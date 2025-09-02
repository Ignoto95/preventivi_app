const path = require('path');
const express = require('express');

module.exports = (app) => {
  app.use('/static', express.static(path.join(__dirname, '../public')));
  app.use('/modelli', express.static(path.join(__dirname, '../public/modelli')));
  app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
};
