import { EnvHttpProxyAgent, fetch as proxyFetch } from 'undici';
import { loadConfig } from './config.js';
import { FakeStoreProducts } from './adapters/fake-store-products.js';
import { SmtpMailer } from './adapters/smtp-mailer.js';
import { CatalogueService } from './services/catalogue-service.js';
import { EnquiryService } from './services/enquiry-service.js';
import { createApp } from './app.js';

const config = loadConfig();
const dispatcher = new EnvHttpProxyAgent();
const source = new FakeStoreProducts(
  config.PRODUCT_API_URL,
  config.CACHE_TTL_MS,
  (url, init) => proxyFetch(url, { ...init, dispatcher }),
);
const catalogue = new CatalogueService(source, config.FEATURED_PRODUCT_IDS);
const enquiries = new EnquiryService(catalogue, new SmtpMailer(config));
const server = createApp({
  catalogue,
  enquiries,
  corsOrigin: config.CORS_ORIGIN,
}).listen(config.PORT, '0.0.0.0', () => {
  console.log(`Catalogue API listening on port ${config.PORT}`);
});

for (const signal of ['SIGTERM', 'SIGINT']) {
  process.once(signal, () => {
    const timeout = setTimeout(() => process.exit(1), 10000);
    timeout.unref();
    server.close(() => {
      void dispatcher.close().finally(() => {
        clearTimeout(timeout);
        process.exit(0);
      });
    });
  });
}
