/**
 * Chill Jamaica — Cloud Functions (2nd gen)
 *
 * Responsibilities of this module:
 *  - Watch for new orders and push an FCM notification to every active admin.
 *  - Record a lightweight analytics entry for each order.
 *
 * Firestore data model (see project spec for full detail):
 *   /orders/{orderId}    — customerPhone, deliveryAddress, items[], total, ...
 *   /admins/{userId}     — email, fcmToken, isActive, role, ...
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
import {getMessaging, MulticastMessage} from "firebase-admin/messaging";

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

/** Shape of a document in /orders/{orderId}. */
interface Order {
  customerPhone: string;
  deliveryAddress: string | null;
  deliveryMethod: "address" | "gps";
  items: OrderItem[];
  subtotal: number;
  deliveryFee: number;
  total: number;
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
