const puppeteer = require('puppeteer');

let browserInstance = null;

const getBrowser = async () => {
  if (!browserInstance) {
    browserInstance = await puppeteer.launch({
      headless: "new",
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-gpu',
        '--no-first-run',
        '--no-zygote',
        '--single-process'
      ],
      timeout: 120000
    });
  }
  return browserInstance;
};

const closeBrowser = async () => {
  if (browserInstance) {
    await browserInstance.close();
    browserInstance = null;
  }
};

// Chiudi il browser quando il processo termina
process.on('SIGINT', closeBrowser);
process.on('SIGTERM', closeBrowser);

module.exports = { getBrowser, closeBrowser };
