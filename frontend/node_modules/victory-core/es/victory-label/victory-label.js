import _isEmpty from "lodash/isEmpty";
import _defaults from "lodash/defaults";
import _assign from "lodash/assign";

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; var ownKeys = Object.keys(source); if (typeof Object.getOwnPropertySymbols === 'function') { ownKeys = ownKeys.concat(Object.getOwnPropertySymbols(source).filter(function (sym) { return Object.getOwnPropertyDescriptor(source, sym).enumerable; })); } ownKeys.forEach(function (key) { _defineProperty(target, key, source[key]); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import React from "react";
import PropTypes from "prop-types";
import VictoryPortal from "../victory-portal/victory-portal";
import CustomPropTypes from "../victory-util/prop-types";
import Helpers from "../victory-util/helpers";
import LabelHelpers from "../victory-util/label-helpers";
import Style from "../victory-util/style";
import Log from "../victory-util/log";
import TSpan from "../victory-primitives/tspan";
import Text from "../victory-primitives/text";
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

  var scaledPoint = Helpers.scalePoint(props, props.datum);
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
      Log.warn("fontSize should be expressed as a number of pixels");
      return defaultStyles.fontSize;
    }
  }

  return defaultStyles.fontSize;
};

var getStyles = function (style, props) {
  var getSingleStyle = function (s) {
    s = s ? _defaults({}, s, defaultStyles) : defaultStyles;
    var baseStyles = Helpers.evaluateStyle(s, props);
    return _assign({}, baseStyles, {
      fontSize: getFontSize(baseStyles)
    });
  };

  return Array.isArray(style) && !_isEmpty(style) ? style.map(function (s) {
    return getSingleStyle(s);
  }) : [getSingleStyle(style)];
};

var getHeight = function (props, type) {
  return Helpers.evaluateProp(props[type], props);
};

var getContent = function (text, props) {
  if (text === undefined || text === null) {
    return undefined;
  }

  if (Array.isArray(text)) {
    return text.map(function (line) {
      return Helpers.evaluateProp(line, props);
    });
  }

  var child = Helpers.evaluateProp(text, props);

  if (child === undefined || child === null) {
    return undefined;
  }

  return Array.isArray(child) ? child : "".concat(child).split("\n");
};

var checkLineHeight = function (lineHeight, val, fallbackVal) {
  if (Array.isArray(lineHeight)) {
    return _isEmpty(lineHeight) ? fallbackVal : val;
  }

  return lineHeight;
};

var getDy = function (props, lineHeight) {
  var style = Array.isArray(props.style) ? props.style[0] : props.style;
  lineHeight = checkLineHeight(lineHeight, lineHeight[0], 1);
  var fontSize = style.fontSize;
  var dy = props.dy ? Helpers.evaluateProp(props.dy, props) : 0;
  var length = props.text.length;
  var capHeight = getHeight(props, "capHeight");
  var verticalAnchor = style.verticalAnchor || props.verticalAnchor;
  var anchor = verticalAnchor ? Helpers.evaluateProp(verticalAnchor, props) : "middle";

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
  var defaultAngle = polar ? LabelHelpers.getPolarAngle(props) : 0;
  var baseAngle = style.angle === undefined ? props.angle : style.angle;
  var angle = baseAngle === undefined ? defaultAngle : baseAngle;
  var transform = props.transform || style.transform;
  var transformPart = transform && Helpers.evaluateProp(transform, props);
  var rotatePart = angle && {
    rotate: [angle, x, y]
  };
  return transformPart || angle ? Style.toTransformString(transformPart, rotatePart) : undefined;
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
  var textAnchor = props.textAnchor ? Helpers.evaluateProp(props.textAnchor, props) : "start";
  var dx = props.dx ? Helpers.evaluateProp(props.dx, props) : 0;
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
    return React.cloneElement(props.tspanComponent, tspanProps);
  });
  return React.cloneElement(props.textComponent, _objectSpread({}, events, {
    direction: direction,
    dx: dx,
    dy: dy,
    x: x,
    y: y,
    transform: transform,
    className: className,
    title: title,
    desc: Helpers.evaluateProp(props.desc, props),
    tabIndex: Helpers.evaluateProp(props.tabIndex, props),
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
  var style = getStyles(props.style, _assign({}, props, {
    text: text
  }));
  return _assign({}, props, {
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
  return props.renderInPortal ? React.createElement(VictoryPortal, null, label) : label;
};

VictoryLabel.displayName = "VictoryLabel";
VictoryLabel.role = "label";
VictoryLabel.defaultStyles = defaultStyles;
VictoryLabel.propTypes = {
  active: PropTypes.bool,
  angle: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  capHeight: PropTypes.oneOfType([PropTypes.string, CustomPropTypes.nonNegative, PropTypes.func]),
  className: PropTypes.string,
  data: PropTypes.array,
  datum: PropTypes.any,
  desc: PropTypes.oneOfType([PropTypes.string, PropTypes.func]),
  direction: PropTypes.oneOf(["rtl", "ltr", "inherit"]),
  dx: PropTypes.oneOfType([PropTypes.number, PropTypes.string, PropTypes.func]),
  dy: PropTypes.oneOfType([PropTypes.number, PropTypes.string, PropTypes.func]),
  events: PropTypes.object,
  id: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  index: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  inline: PropTypes.bool,
  labelPlacement: PropTypes.oneOf(["parallel", "perpendicular", "vertical"]),
  lineHeight: PropTypes.oneOfType([PropTypes.string, CustomPropTypes.nonNegative, PropTypes.func, PropTypes.array]),
  origin: PropTypes.shape({
    x: CustomPropTypes.nonNegative,
    y: CustomPropTypes.nonNegative
  }),
  polar: PropTypes.bool,
  renderInPortal: PropTypes.bool,
  scale: PropTypes.shape({
    x: CustomPropTypes.scale,
    y: CustomPropTypes.scale
  }),
  style: PropTypes.oneOfType([PropTypes.object, PropTypes.array]),
  tabIndex: PropTypes.oneOfType([PropTypes.number, PropTypes.func]),
  text: PropTypes.oneOfType([PropTypes.string, PropTypes.number, PropTypes.func, PropTypes.array]),
  textAnchor: PropTypes.oneOfType([PropTypes.oneOf(["start", "middle", "end", "inherit"]), PropTypes.func]),
  textComponent: PropTypes.element,
  title: PropTypes.string,
  transform: PropTypes.oneOfType([PropTypes.string, PropTypes.object, PropTypes.func]),
  tspanComponent: PropTypes.element,
  verticalAnchor: PropTypes.oneOfType([PropTypes.oneOf(["start", "middle", "end"]), PropTypes.func]),
  x: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  y: PropTypes.oneOfType([PropTypes.number, PropTypes.string])
};
VictoryLabel.defaultProps = {
  direction: "inherit",
  textComponent: React.createElement(Text, null),
  tspanComponent: React.createElement(TSpan, null),
  capHeight: 0.71,
  // Magic number from d3.
  lineHeight: 1
};
export default VictoryLabel;