/**
 * Seeds the /products collection in the Firestore emulator with the
 * standard Chill Jamaica coconut water lineup.
 *
 * This script is idempotent: re-running it will not create duplicate
 * products. Existing products (matched by name) are updated in place
 * rather than duplicated.
 *
 * Usage:
 *   FIRESTORE_EMULATOR_HOST=localhost:8080 npx ts-node scripts/seed_products.ts
 *
 * If FIRESTORE_EMULATOR_HOST is not set, it defaults to "localhost:8080".
 */

import * as admin from "firebase-admin";

const DEFAULT_EMULATOR_HOST = "localhost:8080";
const PROJECT_ID = "chill-coconetwater";

/** The subset of product fields we seed by hand; the rest are derived. */
interface ProductSeed {
  name: string;
  size_ml: number;
  price_jmd: number;
}

/** Full shape of a document written to /products. */
interface ProductDocument extends ProductSeed {
  image_placeholder: string;
  is_available: boolean;
  createdAt: FirebaseFirestore.FieldValue;
}

const PRODUCTS_TO_SEED: ProductSeed[] = [
  {name: "Soda Bottle", size_ml: 500, price_jmd: 400},
  {name: "1/2 Gallon", size_ml: 1890, price_jmd: 1200},
  {name: "1 Gallon", size_ml: 3780, price_jmd: 2000},
  {name: "2.5 Gallon", size_ml: 9460, price_jmd: 4500},
];

/**
 * Points the Admin SDK at the Firestore emulator, unless an explicit
 * host has already been provided via the environment.
 */
function configureEmulatorHost(): void {
  process.env.FIRESTORE_EMULATOR_HOST =
    process.env.FIRESTORE_EMULATOR_HOST ?? DEFAULT_EMULATOR_HOST;
}

/**
 * Derives a stable placeholder image path from a product name, e.g.
 * "1/2 Gallon" -> "placeholders/1-2-gallon.png".
 */
function buildImagePlaceholder(productName: string): string {
  const slug = productName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
  return `placeholders/${slug}.png`;
}

/**
 * Finds an existing product document by its unique name, if any.
 */
async function findExistingProductByName(
  db: FirebaseFirestore.Firestore,
  name: string
): Promise<FirebaseFirestore.QueryDocumentSnapshot | null> {
  const matches = await db
    .collection("products")
    .where("name", "==", name)
    .limit(1)
    .get();

  return matches.empty ? null : matches.docs[0];
}

/**
 * Creates or updates a single product document so that it matches the
 * given seed data. Existing documents keep their original createdAt.
 */
async function upsertProduct(
  db: FirebaseFirestore.Firestore,
  seed: ProductSeed
): Promise<void> {
  const existing = await findExistingProductByName(db, seed.name);

  const fields: Omit<ProductDocument, "createdAt"> = {
    name: seed.name,
    size_ml: seed.size_ml,
    price_jmd: seed.price_jmd,
    image_placeholder: buildImagePlaceholder(seed.name),
    is_available: true,
  };

  if (existing) {
    await existing.ref.update({...fields});
    console.log(`Updated existing product: ${seed.name} (${existing.id})`);
    return;
  }

  const document: ProductDocument = {
    ...fields,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  const created = await db.collection("products").add(document);
  console.log(`Created new product: ${seed.name} (${created.id})`);
}

/** Seeds every product in {@link PRODUCTS_TO_SEED}, sequentially. */
async function seedAllProducts(db: FirebaseFirestore.Firestore): Promise<void> {
  for (const seed of PRODUCTS_TO_SEED) {
    await upsertProduct(db, seed);
  }
}

async function main(): Promise<void> {
  configureEmulatorHost();

  admin.initializeApp({projectId: PROJECT_ID});
  const db = admin.firestore();

  console.log(
    `Seeding products against Firestore emulator at ${process.env.FIRESTORE_EMULATOR_HOST} ` +
      `(project: ${PROJECT_ID})`
  );

  await seedAllProducts(db);

  console.log("Product seeding complete.");
}

main().catch((error: unknown) => {
  console.error("Product seeding failed:", error);
  process.exitCode = 1;
});
