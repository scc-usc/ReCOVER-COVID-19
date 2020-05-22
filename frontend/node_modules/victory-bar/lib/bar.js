"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _isNil2 = _interopRequireDefault(require("lodash/isNil"));

var _isFunction2 = _interopRequireDefault(require("lodash/isFunction"));

var _isPlainObject2 = _interopRequireDefault(require("lodash/isPlainObject"));

var _assign2 = _interopRequireDefault(require("lodash/assign"));

var _react = _interopRequireDefault(require("react"));

var _propTypes = _interopRequireDefault(require("prop-types"));

var _victoryCore = require("victory-core");

var _pathHelperMethods = require("./path-helper-methods");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; var ownKeys = Object.keys(source); if (typeof Object.getOwnPropertySymbols === 'function') { ownKeys = ownKeys.concat(Object.getOwnPropertySymbols(source).filter(function (sym) { return Object.getOwnPropertyDescriptor(source, sym).enumerable; })); } ownKeys.forEach(function (key) { _defineProperty(target, key, source[key]); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

var getBarPath = function (props, width, cornerRadius) {
  if (props.getPath) {
    return (0, _pathHelperMethods.getCustomBarPath)(props, width);
  }

  return props.horizontal ? (0, _pathHelperMethods.getHorizontalBarPath)(props, width, cornerRadius) : (0, _pathHelperMethods.getVerticalBarPath)(props, width, cornerRadius);
};

var getPolarBarPath = function (props, cornerRadius) {
  // TODO Radial bars
  return (0, _pathHelperMethods.getVerticalPolarBarPath)(props, cornerRadius);
};

var getBarWidth = function (barWidth, props) {
  var scale = props.scale,
      data = props.data,
      defaultBarWidth = props.defaultBarWidth,
      style = props.style;

  if (barWidth) {
    return (0, _isFunction2.default)(barWidth) ? _victoryCore.Helpers.evaluateProp(barWidth, props) : barWidth;
  } else if (style.width) {
    return style.width;
  }

  var range = scale.x.range();
  var extent = Math.abs(range[1] - range[0]);
  var bars = data.length + 2;
  var barRatio = props.barRatio || 0.5;
  var defaultWidth = barRatio * (data.length < 2 ? defaultBarWidth : extent / bars);
  return Math.max(1, defaultWidth);
};

var getCornerRadiusFromObject = function (cornerRadius, props) {
  var realCornerRadius = {
    topLeft: 0,
    topRight: 0,
    bottomLeft: 0,
    bottomRight: 0
  };

  var updateCornerRadius = function (corner, fallback) {
    if (!(0, _isNil2.default)(cornerRadius[corner])) {
      realCornerRadius[corner] = _victoryCore.Helpers.evaluateProp(cornerRadius[corner], props);
    } else if (!(0, _isNil2.default)(cornerRadius[fallback])) {
      realCornerRadius[corner] = _victoryCore.Helpers.evaluateProp(cornerRadius[fallback], props);
    }
  };

  updateCornerRadius("topLeft", "top");
  updateCornerRadius("topRight", "top");
  updateCornerRadius("bottomLeft", "bottom");
  updateCornerRadius("bottomRight", "bottom");
  return realCornerRadius;
};

var getCornerRadius = function (cornerRadius, props) {
  var realCornerRadius = {
    topLeft: 0,
    topRight: 0,
    bottomLeft: 0,
    bottomRight: 0
  };

  if (!cornerRadius) {
    return realCornerRadius;
  }

  if ((0, _isPlainObject2.default)(cornerRadius)) {
    return getCornerRadiusFromObject(cornerRadius, props);
  } else {
    realCornerRadius.topLeft = _victoryCore.Helpers.evaluateProp(cornerRadius, props);
    realCornerRadius.topRight = _victoryCore.Helpers.evaluateProp(cornerRadius, props);
    return realCornerRadius;
  }
};

var getStyle = function () {
  var style = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
  var props = arguments.length > 1 ? arguments[1] : undefined;
  var stroke = style.fill || "black";
  var baseStyle = {
    fill: "black",
    stroke: stroke
  };
  return _victoryCore.Helpers.evaluateStyle((0, _assign2.default)(baseStyle, style), props);
};

var evaluateProps = function (props) {
  // Potential evaluated props are 1) `style`, 2) `barWidth` and 3) `cornerRadius`
  var style = getStyle(props.style, props);
  var barWidth = getBarWidth(props.barWidth, (0, _assign2.default)({}, props, {
    style: style
  }));
  var cornerRadius = getCornerRadius(props.cornerRadius, (0, _assign2.default)({}, props, {
    style: style,
    barWidth: barWidth
  }));
  return (0, _assign2.default)({}, props, {
    style: style,
    barWidth: barWidth,
    cornerRadius: cornerRadius
  });
};

var Bar = function (props) {
  props = evaluateProps(props);
  var _props = props,
      polar = _props.polar,
      origin = _props.origin,
      style = _props.style,
      barWidth = _props.barWidth,
      cornerRadius = _props.cornerRadius;
  var path = polar ? getPolarBarPath(props, cornerRadius) : getBarPath(props, barWidth, cornerRadius);
  var defaultTransform = polar && origin ? "translate(".concat(origin.x, ", ").concat(origin.y, ")") : undefined;
  return _react.default.cloneElement(props.pathComponent, _objectSpread({}, props.events, {
    style: style,
    d: path,
    transform: props.transform || defaultTransform,
    className: props.className,
    role: props.role,
    shapeRendering: props.shapeRendering,
    clipPath: props.clipPath,
    desc: _victoryCore.Helpers.evaluateProp(props.desc, props),
    tabIndex: _victoryCore.Helpers.evaluateProp(props.tabIndex, props)
  }));
};

Bar.propTypes = _objectSpread({}, _victoryCore.CommonProps.primitiveProps, {
  alignment: _propTypes.default.oneOf(["start", "middle", "end"]),
  barRatio: _propTypes.default.number,
  barWidth: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.func]),
  cornerRadius: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.func, _propTypes.default.shape({
    top: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.func]),
    topLeft: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.func]),
    topRight: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.func]),
    bottom: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.func]),
    bottomLeft: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.func]),
    bottomRight: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.func])
  })]),
  datum: _propTypes.default.object,
  getPath: _propTypes.default.func,
  horizontal: _propTypes.default.bool,
  pathComponent: _propTypes.default.element,
  width: _propTypes.default.number,
  x: _propTypes.default.number,
  y: _propTypes.default.number,
  y0: _propTypes.default.number
});
Bar.defaultProps = {
  defaultBarWidth: 8,
  pathComponent: _react.default.createElement(_victoryCore.Path, null),
  role: "presentation",
  shapeRendering: "auto"
};
var _default = Bar;
exports.default = _default;