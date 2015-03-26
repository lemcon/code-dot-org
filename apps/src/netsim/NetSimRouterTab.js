/* jshint
 funcscope: true,
 newcap: true,
 nonew: true,
 shadow: false,
 unused: true,

 maxlen: 90,
 maxparams: 3,
 maxstatements: 200
 */
/* global $ */
'use strict';

var markup = require('./NetSimRouterTab.html');
var NetSimBandwidthControl = require('./NetSimBandwidthControl');
var NetSimRouterLogTable = require('./NetSimRouterLogTable');

/**
 * Generator and controller for router information view.
 * @param {jQuery} rootDiv - Parent element for this component.
 * @param {netsimLevelConfiguration} levelConfig
 * @constructor
 */
var NetSimRouterTab = module.exports = function (rootDiv, levelConfig) {
  /**
   * Component root, which we fill whenever we call render()
   * @type {jQuery}
   * @private
   */
  this.rootDiv_ = rootDiv;

  /**
   * @type {netsimLevelConfiguration}
   * @private
   */
  this.levelConfig_ = levelConfig;

  /**
   * @type {NetSimRouterLogTable}
   * @private
   */
  this.routerLogTable_ = null;

  /**
   * @type {NetSimBandwidthControl}
   * @private
   */
  this.bandwidthControl_ = null;

  // Initial render
  this.render();
};

/**
 * Fill the root div with new elements reflecting the current state.
 */
NetSimRouterTab.prototype.render = function () {
  var renderedMarkup = $(markup({}));
  this.rootDiv_.html(renderedMarkup);
  this.routerLogTable_ = new NetSimRouterLogTable(
      this.rootDiv_.find('.router_log_table'), this.levelConfig_);
  this.bandwidthControl_ = new NetSimBandwidthControl(
      this.rootDiv_.find('.bandwidth-control'), function () {});
};

/**
 * @param {Array} logData
 */
NetSimRouterTab.prototype.setRouterLogData = function (logData) {
  this.routerLogTable_.setRouterLogData(logData);
};
