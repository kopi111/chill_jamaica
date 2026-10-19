/**
 * Chill Jamaica — Cloud Functions (2nd gen)
 *
 * Responsibilities of this module:
 *  - Watch for new orders and push an FCM notification to every active admin.
 *  - Send the customer a receipt when their card payment settles.
 *  - Record a lightweight analytics entry for each order.
 *
 * Firestore data model (see project spec for full detail):
 *   /orders/{orderId}    — customerPhone, customerId, payment{}, items[], ...
 *   /admins/{userId}     — email, fcmToken, isActive, role, ...
 *   /customers/{uid}     — fullName, email, phone, photoUrl, fcmToken, ...
 *   /analytics/{autoId}  — orderId (ref), total, itemCount, createdAt
 */

import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  getFirestore,
  DocumentReference,
} from "firebase-admin/firestore";
import {getMessaging, Message, MulticastMessage} from "firebase-admin/messaging";

initializeApp();

const firestore = getFirestore();
const messaging = getMessaging();

/** Maximum number of attempts when sending the FCM multicast message. */
const MAX_SEND_ATTEMPTS = 3;

/** Delay between FCM send retries, in milliseconds. */
const RETRY_DELAY_MS = 1000;

/** A single line item stored on an order. */
interface OrderItem {
  productId: string;
  productName: string;
  size: string;
  quantity: number;
  unitPrice: number;
}

/** The payment facts recorded on an order. Never holds a card number. */
interface Payment {
  method: "card" | "cash_on_delivery";
  status: "paid" | "awaiting_cash" | "declined" | "refunded";
  gatewayReference: string | null;
  cardBrand: string | null;
  cardLast4: string | null;
}

/** Shape of a document in /orders/{orderId}. */
interface Order {
  customerPhone: string;
  customerId: string | null;
  deliveryAddress: string | null;
  deliveryMethod: "address" | "gps";
  items: OrderItem[];
  subtotal: number;
  deliveryFee: number;
  total: number;
  payment?: Payment;
  status: "new" | "processing" | "out_for_delivery" | "delivered";
  adminId: string;
}

/** Shape of a document in /admins/{userId}. */
interface Admin {
  email: string;
  fcmToken: string;
  role: "admin" | "super_admin";
  isActive: boolean;
}

/** Shape of a document in /customers/{uid}. */
interface Customer {
  fullName: string;
  email: string;
  phone: string;
  fcmToken?: string;
}

/**
 * Builds a human-readable summary of an order's items, e.g.
 * "2x 1/2 Gallon + 1x Soda Bottle".
 */
export function buildItemSummary(items: OrderItem[]): string {
  if (items.length === 0) {
    return "No items";
  }

  return items
    .map((item) => `${item.quantity}x ${item.productName}`)
    .join(" + ");
}

/**
 * Sums the quantities of every line item on an order.
 */
export function countItems(items: OrderItem[]): number {
  return items.reduce((sum, item) => sum + item.quantity, 0);
}

/**
 * Fetches every active admin and returns the distinct, non-empty FCM
 * tokens registered to them. Admins with a missing or blank token are
 * skipped rather than causing a failure.
 */
export async function collectAdminTokens(): Promise<string[]> {
  const activeAdmins = await firestore
    .collection("admins")
    .where("isActive", "==", true)
    .get();

  const tokens = activeAdmins.docs
    .map((doc) => (doc.data() as Admin).fcmToken)
    .filter((token): token is string => Boolean(token && token.trim()));

  return Array.from(new Set(tokens));
}

/** Pauses execution for the given number of milliseconds. */
function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Sends a multicast FCM message, retrying on failure up to
 * {@link MAX_SEND_ATTEMPTS} times with a fixed delay between attempts.
 * Returns true if the send ultimately succeeded, false otherwise.
 */
export async function sendWithRetry(
  message: MulticastMessage
): Promise<boolean> {
  for (let attempt = 1; attempt <= MAX_SEND_ATTEMPTS; attempt++) {
    try {
      const response = await messaging.sendEachForMulticast(message);
      logger.info("FCM multicast send succeeded", {
        attempt,
        successCount: response.successCount,
        failureCount: response.failureCount,
      });
      return true;
    } catch (error) {
      logger.warn("FCM multicast send attempt failed", {
        attempt,
        maxAttempts: MAX_SEND_ATTEMPTS,
        error: error instanceof Error ? error.message : String(error),
      });

      const isLastAttempt = attempt === MAX_SEND_ATTEMPTS;
      if (!isLastAttempt) {
        await delay(RETRY_DELAY_MS);
      }
    }
  }

  logger.error("FCM multicast send failed after all retry attempts", {
    maxAttempts: MAX_SEND_ATTEMPTS,
  });
  return false;
}

/**
 * Writes a single /analytics document summarizing the given order.
 */
export async function writeAnalytics(
  orderRef: DocumentReference,
  order: Order
): Promise<void> {
  await firestore.collection("analytics").add({
    orderId: orderRef,
    total: order.total,
    itemCount: countItems(order.items),
    createdAt: FieldValue.serverTimestamp(),
  });
}

/**
 * The customer's registered device token, or null when they have no profile,
 * never granted notification permission, or ordered as a guest.
 */
export async function findCustomerToken(
  customerId: string | null
): Promise<string | null> {
  if (!customerId) {
    return null;
  }

  const snapshot = await firestore
    .collection("customers")
    .doc(customerId)
    .get();

  if (!snapshot.exists) {
    return null;
  }

  const token = (snapshot.data() as Customer).fcmToken;
  return token && token.trim() ? token : null;
}

/**
 * Builds the receipt notification sent to the customer once a card payment
 * has settled.
 */
function buildPaymentReceipt(
  orderId: string,
  order: Order,
  token: string
): Message {
  const payment = order.payment;
  const card =
    payment?.cardBrand && payment?.cardLast4 ?
      `${payment.cardBrand} ••••${payment.cardLast4}` :
      "your card";

  return {
    token,
    notification: {
      title: "Payment Confirmed 🥥",
      body:
        `JMD $${order.total} paid with ${card}. ` +
        "Wi bringing di freshness to yuh!",
    },
    data: {
      orderId,
      total: String(order.total),
      gatewayReference: payment?.gatewayReference ?? "",
    },
    android: {
      notification: {
        channelId: "payments_channel",
        sound: "default",
      },
    },
  };
}

/**
 * Notifies the customer that their payment went through.
 *
 * Silently does nothing for cash orders, guest orders, or customers with no
 * device token — a missing receipt must never fail the order itself.
 */
export async function sendPaymentReceipt(
  orderId: string,
  order: Order
): Promise<void> {
  if (order.payment?.status !== "paid") {
    return;
  }

  const token = await findCustomerToken(order.customerId);
  if (!token) {
    logger.info("No customer token; skipping payment receipt", {orderId});
    return;
  }

  await messaging.send(buildPaymentReceipt(orderId, order, token));
  logger.info("Payment receipt sent", {orderId});
}

/**
 * Builds the FCM multicast message for a newly placed order.
 */
function buildOrderNotification(
  orderId: string,
  order: Order,
  tokens: string[]
): MulticastMessage {
  const itemSummary = buildItemSummary(order.items);
  const deliveryAddress = order.deliveryAddress ?? "";

  return {
    tokens,
    notification: {
      title: "New Coconut Water Order! 🥥",
      body: `JMD ${order.total} — ${itemSummary} — ${order.customerPhone}`,
    },
    data: {
      orderId,
      customerPhone: order.customerPhone,
      deliveryAddress,
      total: String(order.total),
    },
    android: {
      notification: {
        channelId: "orders_channel",
        sound: "default",
      },
    },
  };
}

/**
 * Trigger: fires whenever a new document is created in /orders.
 * Notifies all active admins via FCM and records an analytics entry.
 */
export const onOrderCreated = onDocumentCreated(
  "orders/{orderId}",
  async (event) => {
    const orderId = event.params.orderId;
    const snapshot = event.data;

    if (!snapshot) {
      logger.error("onOrderCreated triggered without a document snapshot", {
        orderId,
      });
      return;
    }

    const order = snapshot.data() as Order;

    try {
      const tokens = await collectAdminTokens();

      if (tokens.length === 0) {
        logger.warn("No active admin FCM tokens found; skipping FCM send", {
          orderId,
        });
      } else {
        const message = buildOrderNotification(orderId, order, tokens);
        await sendWithRetry(message);
      }

      await sendPaymentReceipt(orderId, order);
      await writeAnalytics(snapshot.ref, order);
      logger.info("Order processed successfully", {orderId});
    } catch (error) {
      logger.error("Failed to process new order", {
        orderId,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }
);
