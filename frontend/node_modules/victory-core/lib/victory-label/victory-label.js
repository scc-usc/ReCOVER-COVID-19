"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _isEmpty2 = _interopRequireDefault(require("lodash/isEmpty"));

var _defaults2 = _interopRequireDefault(require("lodash/defaults"));

var _assign2 = _interopRequireDefault(require("lodash/assign"));

var _react = _interopRequireDefault(require("react"));

var _propTypes = _interopRequireDefault(require("prop-types"));

var _victoryPortal = _interopRequireDefault(require("../victory-portal/victory-portal"));

var _propTypes2 = _interopRequireDefault(require("../victory-util/prop-types"));

var _helpers = _interopRequireDefault(require("../victory-util/helpers"));

var _labelHelpers = _interopRequireDefault(require("../victory-util/label-helpers"));

var _style = _interopRequireDefault(require("../victory-util/style"));

var _log = _interopRequireDefault(require("../victory-util/log"));

var _tspan = _interopRequireDefault(require("../victory-primitives/tspan"));

var _text = _interopRequireDefault(require("../victory-primitives/text"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; var ownKeys = Object.keys(source); if (typeof Object.getOwnPropertySymbols === 'function') { ownKeys = ownKeys.concat(Object.getOwnPropertySymbols(source).filter(function (sym) { return Object.getOwnPropertyDescriptor(source, sym).enumerable; })); } ownKeys.forEach(function (key) { _defineProperty(target, key, source[key]); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

var defaultStyles = {
  fill: "#252525",
  fontSize: 14,
  fontFamily: "'Gill Sans', 'Gill Sans MT', 'Ser­avek', 'Trebuchet MS', sans-serif",
  stroke: "transparent"
};

var getPosition = function (props, dimension) {
  if (!props.datum) {
    return 0;
  }

  var scaledPoint = _helpers.default.scalePoint(props, props.datum);

  return scaledPoint[dimension];
};

var getFontSize = function (style) {
  var baseSize = style && style.fontSize;

  if (typeof baseSize === "number") {
    return baseSize;
  } else if (baseSize === undefined || baseSize === null) {
    return defaultStyles.fontSize;
  } else if (typeof baseSize === "string") {
    var fontSize = +baseSize.replace("px", "");

    if (!isNaN(fontSize)) {
      return fontSize;
    } else {
      _log.default.warn("fontSize should be expressed as a number of pixels");

      return defaultStyles.fontSize;
    }
  }

  return defaultStyles.fontSize;
};

var getStyles = function (style, props) {
  var getSingleStyle = function (s) {
    s = s ? (0, _defaults2.default)({}, s, defaultStyles) : defaultStyles;

    var baseStyles = _helpers.default.evaluateStyle(s, props);

    return (0, _assign2.default)({}, baseStyles, {
      fontSize: getFontSize(baseStyles)
    });
  };

  return Array.isArray(style) && !(0, _isEmpty2.default)(style) ? style.map(function (s) {
    return getSingleStyle(s);
  }) : [getSingleStyle(style)];
};

var getHeight = function (props, type) {
  return _helpers.default.evaluateProp(props[type], props);
};

var getContent = function (text, props) {
  if (text === undefined || text === null) {
    return undefined;
  }

  if (Array.isArray(text)) {
    return text.map(function (line) {
      return _helpers.default.evaluateProp(line, props);
    });
  }

  var child = _helpers.default.evaluateProp(text, props);

  if (child === undefined || child === null) {
    return undefined;
  }

  return Array.isArray(child) ? child : "".concat(child).split("\n");
};

var checkLineHeight = function (lineHeight, val, fallbackVal) {
  if (Array.isArray(lineHeight)) {
    return (0, _isEmpty2.default)(lineHeight) ? fallbackVal : val;
  }

  return lineHeight;
};

var getDy = function (props, lineHeight) {
  var style = Array.isArray(props.style) ? props.style[0] : props.style;
  lineHeight = checkLineHeight(lineHeight, lineHeight[0], 1);
  var fontSize = style.fontSize;
  var dy = props.dy ? _helpers.default.evaluateProp(props.dy, props) : 0;
  var length = props.text.length;
  var capHeight = getHeight(props, "capHeight");
  var verticalAnchor = style.verticalAnchor || props.verticalAnchor;
  var anchor = verticalAnchor ? _helpers.default.evaluateProp(verticalAnchor, props) : "middle";

  switch (anchor) {
    case "end":
      return dy + (capHeight / 2 + (0.5 - length) * lineHeight) * fontSize;

    case "middle":
      return dy + (capHeight / 2 + (0.5 - length / 2) * lineHeight) * fontSize;

    default:
      return dy + (capHeight / 2 + lineHeight / 2) * fontSize;
  }
};

var getTransform = function (props) {
  var x = props.x,
      y = props.y,
      polar = props.polar,
      style = props.style;
  var defaultAngle = polar ? _labelHelpers.default.getPolarAngle(props) : 0;
  var baseAngle = style.angle === undefined ? props.angle : style.angle;
  var angle = baseAngle === undefined ? defaultAngle : baseAngle;
  var transform = props.transform || style.transform;

  var transformPart = transform && _helpers.default.evaluateProp(transform, props);

  var rotatePart = angle && {
    rotate: [angle, x, y]
  };
  return transformPart || angle ? _style.default.toTransformString(transformPart, rotatePart) : undefined;
};

var renderElements = function (props) {
  var inline = props.inline,
      className = props.className,
      title = props.title,
      events = props.events,
      direction = props.direction,
      text = props.text,
      style = props.style;
  var lineHeight = getHeight(props, "lineHeight");
  var textAnchor = props.textAnchor ? _helpers.default.evaluateProp(props.textAnchor, props) : "start";
  var dx = props.dx ? _helpers.default.evaluateProp(props.dx, props) : 0;
  var dy = getDy(props, lineHeight);
  var transform = getTransform(props);
  var x = props.x !== undefined ? props.x : getPosition(props, "x");
  var y = props.y !== undefined ? props.y : getPosition(props, "y");
  var textChildren = text.map(function (line, i) {
    var currentStyle = style[i] || style[0];
    var lastStyle = style[i - 1] || style[0];
    var fontSize = (currentStyle.fontSize + lastStyle.fontSize) / 2;
    var currentLineHeight = checkLineHeight(lineHeight, (lineHeight[i] + (lineHeight[i - 1] || lineHeight[0])) / 2, 1);
    var tspanProps = {
      key: "".concat(props.id, "-key-").concat(i),
      x: !inline ? props.x : undefined,
      dx: dx,
      dy: i && !inline ? currentLineHeight * fontSize : undefined,
      textAnchor: currentStyle.textAnchor || textAnchor,
      style: currentStyle,
      children: line
    };
    return _react.default.cloneElement(props.tspanComponent, tspanProps);
  });
  return _react.default.cloneElement(props.textComponent, _objectSpread({}, events, {
    direction: direction,
    dx: dx,
    dy: dy,
    x: x,
    y: y,
    transform: transform,
    className: className,
    title: title,
    desc: _helpers.default.evaluateProp(props.desc, props),
    tabIndex: _helpers.default.evaluateProp(props.tabIndex, props),
    id: props.id
  }), textChildren);
};

var evaluateProps = function (props) {
  /* Potential evaluated props are
    1) text
    2) style
    3) everything else
  */
  var text = getContent(props.text, props);
  var style = getStyles(props.style, (0, _assign2.default)({}, props, {
    text: text
  }));
  return (0, _assign2.default)({}, props, {
    style: style,
    text: text
  });
};

var VictoryLabel = function (props) {
  props = evaluateProps(props);

  if (props.text === null || props.text === undefined) {
    return null;
  }

  var label = renderElements(props);
  return props.renderInPortal ? _react.default.createElement(_victoryPortal.default, null, label) : label;
};

VictoryLabel.displayName = "VictoryLabel";
VictoryLabel.role = "label";
VictoryLabel.defaultStyles = defaultStyles;
VictoryLabel.propTypes = {
  active: _propTypes.default.bool,
  angle: _propTypes.default.oneOfType([_propTypes.default.string, _propTypes.default.number]),
  capHeight: _propTypes.default.oneOfType([_propTypes.default.string, _propTypes2.default.nonNegative, _propTypes.default.func]),
  className: _propTypes.default.string,
  data: _propTypes.default.array,
  datum: _propTypes.default.any,
  desc: _propTypes.default.oneOfType([_propTypes.default.string, _propTypes.default.func]),
  direction: _propTypes.default.oneOf(["rtl", "ltr", "inherit"]),
  dx: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.string, _propTypes.default.func]),
  dy: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.string, _propTypes.default.func]),
  events: _propTypes.default.object,
  id: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.string]),
  index: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.string]),
  inline: _propTypes.default.bool,
  labelPlacement: _propTypes.default.oneOf(["parallel", "perpendicular", "vertical"]),
  lineHeight: _propTypes.default.oneOfType([_propTypes.default.string, _propTypes2.default.nonNegative, _propTypes.default.func, _propTypes.default.array]),
  origin: _propTypes.default.shape({
    x: _propTypes2.default.nonNegative,
    y: _propTypes2.default.nonNegative
  }),
  polar: _propTypes.default.bool,
  renderInPortal: _propTypes.default.bool,
  scale: _propTypes.default.shape({
    x: _propTypes2.default.scale,
    y: _propTypes2.default.scale
  }),
  style: _propTypes.default.oneOfType([_propTypes.default.object, _propTypes.default.array]),
  tabIndex: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.func]),
  text: _propTypes.default.oneOfType([_propTypes.default.string, _propTypes.default.number, _propTypes.default.func, _propTypes.default.array]),
  textAnchor: _propTypes.default.oneOfType([_propTypes.default.oneOf(["start", "middle", "end", "inherit"]), _propTypes.default.func]),
  textComponent: _propTypes.default.element,
  title: _propTypes.default.string,
  transform: _propTypes.default.oneOfType([_propTypes.default.string, _propTypes.default.object, _propTypes.default.func]),
  tspanComponent: _propTypes.default.element,
  verticalAnchor: _propTypes.default.oneOfType([_propTypes.default.oneOf(["start", "middle", "end"]), _propTypes.default.func]),
  x: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.string]),
  y: _propTypes.default.oneOfType([_propTypes.default.number, _propTypes.default.string])
};
VictoryLabel.defaultProps = {
  direction: "inherit",
  textComponent: _react.default.createElement(_text.default, null),
  tspanComponent: _react.default.createElement(_tspan.default, null),
  capHeight: 0.71,
  // Magic number from d3.
  lineHeight: 1
};
var _default = VictoryLabel;
exports.default = _default;