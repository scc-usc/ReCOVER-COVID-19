'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var React = require('react');
var React__default = _interopDefault(React);
var PropTypes = _interopDefault(require('prop-types'));
var reactMotion = require('react-motion');
var core = require('@nivo/core');
var isPlainObject = _interopDefault(require('lodash/isPlainObject'));
var filter = _interopDefault(require('lodash/filter'));
var omit = _interopDefault(require('lodash/omit'));

var annotationSpecPropType = PropTypes.shape({
  match: PropTypes.oneOfType([PropTypes.func, PropTypes.object]).isRequired,
  type: PropTypes.oneOf(['circle', 'rect', 'dot']).isRequired,
  noteX: PropTypes.oneOfType([PropTypes.number, PropTypes.shape({
    abs: PropTypes.number.isRequired
  })]).isRequired,
  noteY: PropTypes.oneOfType([PropTypes.number, PropTypes.shape({
    abs: PropTypes.number.isRequired
  })]).isRequired,
  noteWidth: PropTypes.number,
  noteTextOffset: PropTypes.number,
  note: PropTypes.oneOfType([PropTypes.node, PropTypes.func]).isRequired,
  offset: PropTypes.number
});
var defaultProps = {
  noteWidth: 120,
  noteTextOffset: 8,
  animate: true,
  motionStiffness: 90,
  motionDamping: 13
};

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; var ownKeys = Object.keys(Object(source)); if (typeof Object.getOwnPropertySymbols === 'function') { ownKeys = ownKeys.concat(Object.getOwnPropertySymbols(source).filter(function (sym) { return Object.getOwnPropertyDescriptor(source, sym).enumerable; })); } ownKeys.forEach(function (key) { _defineProperty(target, key, source[key]); }); } return target; }
function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
var defaultPositionAccessor = function defaultPositionAccessor(item) {
  return {
    x: item.x,
    y: item.y
  };
};
var bindAnnotations = function bindAnnotations(_ref) {
  var items = _ref.items,
      annotations = _ref.annotations,
      _ref$getPosition = _ref.getPosition,
      getPosition = _ref$getPosition === void 0 ? defaultPositionAccessor : _ref$getPosition,
      getDimensions = _ref.getDimensions;
  return annotations.reduce(function (acc, annotation) {
    filter(items, annotation.match).forEach(function (item) {
      var position = getPosition(item);
      var dimensions = getDimensions(item, annotation.offset || 0);
      acc.push(_objectSpread({}, omit(annotation, ['match', 'offset']), position, dimensions, {
        datum: item,
        size: annotation.size || dimensions.size
      }));
    });
    return acc;
  }, []);
};
var getLinkAngle = function getLinkAngle(sourceX, sourceY, targetX, targetY) {
  var angle = Math.atan2(targetY - sourceY, targetX - sourceX);
  return core.absoluteAngleDegrees(core.radiansToDegrees(angle));
};
var computeAnnotation = function computeAnnotation(_ref2) {
  var type = _ref2.type,
      x = _ref2.x,
      y = _ref2.y,
      size = _ref2.size,
      width = _ref2.width,
      height = _ref2.height,
      noteX = _ref2.noteX,
      noteY = _ref2.noteY,
      _ref2$noteWidth = _ref2.noteWidth,
      noteWidth = _ref2$noteWidth === void 0 ? defaultProps.noteWidth : _ref2$noteWidth,
      _ref2$noteTextOffset = _ref2.noteTextOffset,
      noteTextOffset = _ref2$noteTextOffset === void 0 ? defaultProps.noteTextOffset : _ref2$noteTextOffset;
  var computedNoteX;
  var computedNoteY;
  if (isPlainObject(noteX)) {
    if (noteX.abs !== undefined) {
      computedNoteX = noteX.abs;
    }
  } else {
    computedNoteX = x + noteX;
  }
  if (isPlainObject(noteY)) {
    if (noteY.abs !== undefined) {
      computedNoteY = noteY.abs;
    }
  } else {
    computedNoteY = y + noteY;
  }
  var computedX = x;
  var computedY = y;
  var angle = getLinkAngle(x, y, computedNoteX, computedNoteY);
  if (type === 'circle') {
    var position = core.positionFromAngle(core.degreesToRadians(angle), size / 2);
    computedX += position.x;
    computedY += position.y;
  }
  if (type === 'rect') {
    var eighth = Math.round((angle + 90) / 45) % 8;
    if (eighth === 0) {
      computedY -= height / 2;
    }
    if (eighth === 1) {
      computedX += width / 2;
      computedY -= height / 2;
    }
    if (eighth === 2) {
      computedX += width / 2;
    }
    if (eighth === 3) {
      computedX += width / 2;
      computedY += height / 2;
    }
    if (eighth === 4) {
      computedY += height / 2;
    }
    if (eighth === 5) {
      computedX -= width / 2;
      computedY += height / 2;
    }
    if (eighth === 6) {
      computedX -= width / 2;
    }
    if (eighth === 7) {
      computedX -= width / 2;
      computedY -= height / 2;
    }
  }
  var textX = computedNoteX;
  var textY = computedNoteY - noteTextOffset;
  var noteLineX = computedNoteX;
  var noteLineY = computedNoteY;
  if ((angle + 90) % 360 > 180) {
    textX -= noteWidth;
    noteLineX -= noteWidth;
  } else {
    noteLineX += noteWidth;
  }
  return {
    points: [[computedX, computedY], [computedNoteX, computedNoteY], [noteLineX, noteLineY]],
    text: [textX, textY],
    angle: angle + 90
  };
};

function _objectSpread$1(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; var ownKeys = Object.keys(Object(source)); if (typeof Object.getOwnPropertySymbols === 'function') { ownKeys = ownKeys.concat(Object.getOwnPropertySymbols(source).filter(function (sym) { return Object.getOwnPropertyDescriptor(source, sym).enumerable; })); } ownKeys.forEach(function (key) { _defineProperty$1(target, key, source[key]); }); } return target; }
function _defineProperty$1(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
var useAnnotations = function useAnnotations(_ref) {
  var items = _ref.items,
      annotations = _ref.annotations,
      getPosition = _ref.getPosition,
      getDimensions = _ref.getDimensions;
  return React.useMemo(function () {
    return bindAnnotations({
      items: items,
      annotations: annotations,
      getPosition: getPosition,
      getDimensions: getDimensions
    });
  }, [items, annotations, getPosition, getDimensions]);
};
var useComputedAnnotations = function useComputedAnnotations(_ref2) {
  var annotations = _ref2.annotations,
      containerWidth = _ref2.containerWidth,
      containerHeight = _ref2.containerHeight;
  return React.useMemo(function () {
    return annotations.map(function (annotation) {
      return _objectSpread$1({}, annotation, {
        computed: computeAnnotation(_objectSpread$1({
          containerWidth: containerWidth,
          containerHeight: containerHeight
        }, annotation))
      });
    });
  }, [annotations, containerWidth, containerHeight]);
};
var useComputedAnnotation = function useComputedAnnotation(_ref3) {
  var type = _ref3.type,
      containerWidth = _ref3.containerWidth,
      containerHeight = _ref3.containerHeight,
      x = _ref3.x,
      y = _ref3.y,
      size = _ref3.size,
      width = _ref3.width,
      height = _ref3.height,
      noteX = _ref3.noteX,
      noteY = _ref3.noteY,
      noteWidth = _ref3.noteWidth,
      noteTextOffset = _ref3.noteTextOffset;
  return React.useMemo(function () {
    return computeAnnotation({
      type: type,
      containerWidth: containerWidth,
      containerHeight: containerHeight,
      x: x,
      y: y,
      size: size,
      width: width,
      height: height,
      noteX: noteX,
      noteY: noteY,
      noteWidth: noteWidth,
      noteTextOffset: noteTextOffset
    });
  }, [type, containerWidth, containerHeight, x, y, size, width, height, noteX, noteY, noteWidth, noteTextOffset]);
};

function _objectSpread$2(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; var ownKeys = Object.keys(Object(source)); if (typeof Object.getOwnPropertySymbols === 'function') { ownKeys = ownKeys.concat(Object.getOwnPropertySymbols(source).filter(function (sym) { return Object.getOwnPropertyDescriptor(source, sym).enumerable; })); } ownKeys.forEach(function (key) { _defineProperty$2(target, key, source[key]); }); } return target; }
function _defineProperty$2(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
var AnnotationNote = React.memo(function (_ref) {
  var datum = _ref.datum,
      x = _ref.x,
      y = _ref.y,
      note = _ref.note;
  var theme = core.useTheme();
  if (typeof note === 'function') {
    return note({
      x: x,
      y: y,
      datum: datum
    });
  }
  return React__default.createElement(React__default.Fragment, null, theme.annotations.text.outlineWidth > 0 && React__default.createElement("text", {
    x: x,
    y: y,
    style: _objectSpread$2({}, theme.annotations.text, {
      strokeLinejoin: 'round',
      strokeWidth: theme.annotations.text.outlineWidth * 2,
      stroke: theme.annotations.text.outlineColor
    })
  }, note), React__default.createElement("text", {
    x: x,
    y: y,
    style: omit(theme.annotations.text, ['outlineWidth', 'outlineColor'])
  }, note));
});
AnnotationNote.displayName = 'AnnotationNote';
AnnotationNote.propTypes = {
  datum: PropTypes.object.isRequired,
  x: PropTypes.number.isRequired,
  y: PropTypes.number.isRequired,
  note: PropTypes.oneOfType([PropTypes.node, PropTypes.func]).isRequired
};
AnnotationNote.defaultProps = {};

function _objectSpread$3(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; var ownKeys = Object.keys(Object(source)); if (typeof Object.getOwnPropertySymbols === 'function') { ownKeys = ownKeys.concat(Object.getOwnPropertySymbols(source).filter(function (sym) { return Object.getOwnPropertyDescriptor(source, sym).enumerable; })); } ownKeys.forEach(function (key) { _defineProperty$3(target, key, source[key]); }); } return target; }
function _defineProperty$3(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
var AnnotationLink = React.memo(function (_ref) {
  var points = _ref.points,
      isOutline = _ref.isOutline;
  var theme = core.useTheme();
  var _useMotionConfig = core.useMotionConfig(),
      animate = _useMotionConfig.animate,
      springConfig = _useMotionConfig.springConfig;
  if (isOutline && theme.annotations.link.outlineWidth <= 0) {
    return null;
  }
  var style = _objectSpread$3({}, theme.annotations.link);
  if (isOutline) {
    style.strokeLinecap = 'square';
    style.strokeWidth = theme.annotations.link.strokeWidth + theme.annotations.link.outlineWidth * 2;
    style.stroke = theme.annotations.link.outlineColor;
  }
  var path = "M".concat(points[0][0], ",").concat(points[0][1]);
  points.slice(1).forEach(function (point) {
    path = "".concat(path, " L").concat(point[0], ",").concat(point[1]);
  });
  if (!animate) {
    return React__default.createElement("path", {
      fill: "none",
      d: path,
      style: style
    });
  }
  return React__default.createElement(core.SmartMotion, {
    style: function style(spring) {
      return {
        d: spring(path, springConfig)
      };
    }
  }, function (interpolated) {
    return React__default.createElement("path", {
      fill: "none",
      d: interpolated.d,
      style: style
    });
  });
});
AnnotationLink.displayName = 'AnnotationLink';
AnnotationLink.propTypes = {
  points: PropTypes.arrayOf(PropTypes.array).isRequired,
  isOutline: PropTypes.bool.isRequired
};
AnnotationLink.defaultProps = {
  isOutline: false
};

function _objectSpread$4(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; var ownKeys = Object.keys(Object(source)); if (typeof Object.getOwnPropertySymbols === 'function') { ownKeys = ownKeys.concat(Object.getOwnPropertySymbols(source).filter(function (sym) { return Object.getOwnPropertyDescriptor(source, sym).enumerable; })); } ownKeys.forEach(function (key) { _defineProperty$4(target, key, source[key]); }); } return target; }
function _defineProperty$4(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
var CircleAnnotationOutline = React.memo(function (_ref) {
  var x = _ref.x,
      y = _ref.y,
      size = _ref.size;
  var theme = core.useTheme();
  var _useMotionConfig = core.useMotionConfig(),
      animate = _useMotionConfig.animate,
      springConfig = _useMotionConfig.springConfig;
  if (!animate) {
    return React__default.createElement(React__default.Fragment, null, theme.annotations.outline.outlineWidth > 0 && React__default.createElement("circle", {
      cx: x,
      cy: y,
      r: size / 2,
      style: _objectSpread$4({}, theme.annotations.outline, {
        fill: 'none',
        strokeWidth: theme.annotations.outline.strokeWidth + theme.annotations.outline.outlineWidth * 2,
        stroke: theme.annotations.outline.outlineColor
      })
    }), React__default.createElement("circle", {
      cx: x,
      cy: y,
      r: size / 2,
      style: theme.annotations.outline
    }));
  }
  return React__default.createElement(reactMotion.Motion, {
    style: {
      x: reactMotion.spring(x, springConfig),
      y: reactMotion.spring(y, springConfig),
      size: reactMotion.spring(size, springConfig)
    }
  }, function (interpolated) {
    return React__default.createElement(React__default.Fragment, null, theme.annotations.outline.outlineWidth > 0 && React__default.createElement("circle", {
      cx: interpolated.x,
      cy: interpolated.y,
      r: interpolated.size / 2,
      style: _objectSpread$4({}, theme.annotations.outline, {
        fill: 'none',
        strokeWidth: theme.annotations.outline.strokeWidth + theme.annotations.outline.outlineWidth * 2,
        stroke: theme.annotations.outline.outlineColor
      })
    }), React__default.createElement("circle", {
      cx: interpolated.x,
      cy: interpolated.y,
      r: interpolated.size / 2,
      style: theme.annotations.outline
    }));
  });
});
CircleAnnotationOutline.displayName = 'CircleAnnotationOutline';
CircleAnnotationOutline.propTypes = {
  x: PropTypes.number.isRequired,
  y: PropTypes.number.isRequired,
  size: PropTypes.number.isRequired
};

function _objectSpread$5(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; var ownKeys = Object.keys(Object(source)); if (typeof Object.getOwnPropertySymbols === 'function') { ownKeys = ownKeys.concat(Object.getOwnPropertySymbols(source).filter(function (sym) { return Object.getOwnPropertyDescriptor(source, sym).enumerable; })); } ownKeys.forEach(function (key) { _defineProperty$5(target, key, source[key]); }); } return target; }
function _defineProperty$5(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
var DotAnnotationOutline = React.memo(function (_ref) {
  var x = _ref.x,
      y = _ref.y,
      size = _ref.size;
  var theme = core.useTheme();
  var _useMotionConfig = core.useMotionConfig(),
      animate = _useMotionConfig.animate,
      springConfig = _useMotionConfig.springConfig;
  if (!animate) {
    return React__default.createElement(React__default.Fragment, null, theme.annotations.outline.outlineWidth > 0 && React__default.createElement("circle", {
      cx: x,
      cy: y,
      r: size / 2,
      style: _objectSpread$5({}, theme.annotations.outline, {
        fill: 'none',
        strokeWidth: theme.annotations.outline.outlineWidth * 2,
        stroke: theme.annotations.outline.outlineColor
      })
    }), React__default.createElement("circle", {
      cx: x,
      cy: y,
      r: size / 2,
      style: theme.annotations.symbol
    }));
  }
  return React__default.createElement(reactMotion.Motion, {
    style: {
      x: reactMotion.spring(x, springConfig),
      y: reactMotion.spring(y, springConfig),
      size: reactMotion.spring(size, springConfig)
    }
  }, function (interpolated) {
    return React__default.createElement(React__default.Fragment, null, theme.annotations.outline.outlineWidth > 0 && React__default.createElement("circle", {
      cx: interpolated.x,
      cy: interpolated.y,
      r: interpolated.size / 2,
      style: _objectSpread$5({}, theme.annotations.outline, {
        fill: 'none',
        strokeWidth: theme.annotations.outline.outlineWidth * 2,
        stroke: theme.annotations.outline.outlineColor
      })
    }), React__default.createElement("circle", {
      cx: interpolated.x,
      cy: interpolated.y,
      r: interpolated.size / 2,
      style: theme.annotations.symbol
    }));
  });
});
DotAnnotationOutline.displayName = 'DotAnnotationOutline';
DotAnnotationOutline.propTypes = {
  x: PropTypes.number.isRequired,
  y: PropTypes.number.isRequired,
  size: PropTypes.number.isRequired
};
DotAnnotationOutline.defaultProps = {
  size: 4
};

function _objectSpread$6(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; var ownKeys = Object.keys(Object(source)); if (typeof Object.getOwnPropertySymbols === 'function') { ownKeys = ownKeys.concat(Object.getOwnPropertySymbols(source).filter(function (sym) { return Object.getOwnPropertyDescriptor(source, sym).enumerable; })); } ownKeys.forEach(function (key) { _defineProperty$6(target, key, source[key]); }); } return target; }
function _defineProperty$6(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
var RectAnnotationOutline = React.memo(function (_ref) {
  var x = _ref.x,
      y = _ref.y,
      width = _ref.width,
      height = _ref.height;
  var theme = core.useTheme();
  var _useMotionConfig = core.useMotionConfig(),
      animate = _useMotionConfig.animate,
      springConfig = _useMotionConfig.springConfig;
  if (!animate) {
    return React__default.createElement(React__default.Fragment, null, theme.annotations.outline.outlineWidth > 0 && React__default.createElement("rect", {
      x: x - width / 2,
      y: y - height / 2,
      width: width,
      height: height,
      style: _objectSpread$6({}, theme.annotations.outline, {
        fill: 'none',
        strokeWidth: theme.annotations.outline.strokeWidth + theme.annotations.outline.outlineWidth * 2,
        stroke: theme.annotations.outline.outlineColor
      })
    }), React__default.createElement("rect", {
      x: x - width / 2,
      y: y - height / 2,
      width: width,
      height: height,
      style: theme.annotations.outline
    }));
  }
  return React__default.createElement(reactMotion.Motion, {
    style: {
      x: reactMotion.spring(x - width / 2, springConfig),
      y: reactMotion.spring(y - height / 2, springConfig),
      width: reactMotion.spring(width, springConfig),
      height: reactMotion.spring(height, springConfig)
    }
  }, function (interpolated) {
    return React__default.createElement(React__default.Fragment, null, theme.annotations.outline.outlineWidth > 0 && React__default.createElement("rect", {
      x: interpolated.x,
      y: interpolated.y,
      width: interpolated.width,
      height: interpolated.height,
      style: _objectSpread$6({}, theme.annotations.outline, {
        fill: 'none',
        strokeWidth: theme.annotations.outline.strokeWidth + theme.annotations.outline.outlineWidth * 2,
        stroke: theme.annotations.outline.outlineColor
      })
    }), React__default.createElement("rect", {
      x: interpolated.x,
      y: interpolated.y,
      width: interpolated.width,
      height: interpolated.height,
      style: theme.annotations.outline
    }));
  });
});
RectAnnotationOutline.displayName = 'RectAnnotationOutline';
RectAnnotationOutline.propTypes = {
  x: PropTypes.number.isRequired,
  y: PropTypes.number.isRequired,
  width: PropTypes.number.isRequired,
  height: PropTypes.number.isRequired
};

var Annotation = React.memo(function (_ref) {
  var datum = _ref.datum,
      type = _ref.type,
      containerWidth = _ref.containerWidth,
      containerHeight = _ref.containerHeight,
      x = _ref.x,
      y = _ref.y,
      size = _ref.size,
      width = _ref.width,
      height = _ref.height,
      noteX = _ref.noteX,
      noteY = _ref.noteY,
      noteWidth = _ref.noteWidth,
      noteTextOffset = _ref.noteTextOffset,
      note = _ref.note;
  var _useMotionConfig = core.useMotionConfig(),
      animate = _useMotionConfig.animate,
      springConfig = _useMotionConfig.springConfig;
  var computed = useComputedAnnotation({
    type: type,
    containerWidth: containerWidth,
    containerHeight: containerHeight,
    x: x,
    y: y,
    size: size,
    width: width,
    height: height,
    noteX: noteX,
    noteY: noteY,
    noteWidth: noteWidth,
    noteTextOffset: noteTextOffset
  });
  return React__default.createElement(React__default.Fragment, null, React__default.createElement(AnnotationLink, {
    points: computed.points,
    isOutline: true
  }), type === 'circle' && React__default.createElement(CircleAnnotationOutline, {
    x: x,
    y: y,
    size: size
  }), type === 'dot' && React__default.createElement(DotAnnotationOutline, {
    x: x,
    y: y,
    size: size
  }), type === 'rect' && React__default.createElement(RectAnnotationOutline, {
    x: x,
    y: y,
    width: width,
    height: height
  }), React__default.createElement(AnnotationLink, {
    points: computed.points
  }), !animate && React__default.createElement(AnnotationNote, {
    x: computed.text[0],
    y: computed.text[1],
    note: note
  }), animate && React__default.createElement(reactMotion.Motion, {
    style: {
      x: reactMotion.spring(computed.text[0], springConfig),
      y: reactMotion.spring(computed.text[1], springConfig)
    }
  }, function (interpolated) {
    return React__default.createElement(AnnotationNote, {
      datum: datum,
      x: interpolated.x,
      y: interpolated.y,
      note: note
    });
  }));
});
Annotation.displayName = 'Annotation';
Annotation.propTypes = {
  datum: PropTypes.object.isRequired,
  type: PropTypes.oneOf(['circle', 'rect', 'dot']).isRequired,
  containerWidth: PropTypes.number.isRequired,
  containerHeight: PropTypes.number.isRequired,
  x: PropTypes.number.isRequired,
  y: PropTypes.number.isRequired,
  size: PropTypes.number,
  width: PropTypes.number,
  height: PropTypes.number,
  noteX: PropTypes.oneOfType([PropTypes.number, PropTypes.shape({
    abs: PropTypes.number.isRequired
  })]).isRequired,
  noteY: PropTypes.oneOfType([PropTypes.number, PropTypes.shape({
    abs: PropTypes.number.isRequired
  })]).isRequired,
  noteWidth: PropTypes.number.isRequired,
  noteTextOffset: PropTypes.number.isRequired,
  note: PropTypes.oneOfType([PropTypes.node, PropTypes.func]).isRequired
};
Annotation.defaultProps = {
  noteWidth: defaultProps.noteWidth,
  noteTextOffset: defaultProps.noteTextOffset
};

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _nonIterableRest(); }
function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance"); }
function _iterableToArrayLimit(arr, i) { if (!(Symbol.iterator in Object(arr) || Object.prototype.toString.call(arr) === "[object Arguments]")) { return; } var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }
function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }
var drawPoints = function drawPoints(ctx, points) {
  points.forEach(function (_ref, index) {
    var _ref2 = _slicedToArray(_ref, 2),
        x = _ref2[0],
        y = _ref2[1];
    if (index === 0) {
      ctx.moveTo(x, y);
    } else {
      ctx.lineTo(x, y);
    }
  });
};
var renderAnnotationsToCanvas = function renderAnnotationsToCanvas(ctx, _ref3) {
  var annotations = _ref3.annotations,
      theme = _ref3.theme;
  if (annotations.length === 0) return;
  ctx.save();
  annotations.forEach(function (annotation) {
    if (theme.annotations.link.outlineWidth > 0) {
      ctx.lineCap = 'square';
      ctx.strokeStyle = theme.annotations.link.outlineColor;
      ctx.lineWidth = theme.annotations.link.strokeWidth + theme.annotations.link.outlineWidth * 2;
      ctx.beginPath();
      drawPoints(ctx, annotation.computed.points);
      ctx.stroke();
      ctx.lineCap = 'butt';
    }
    if (annotation.type === 'circle' && theme.annotations.outline.outlineWidth > 0) {
      ctx.strokeStyle = theme.annotations.outline.outlineColor;
      ctx.lineWidth = theme.annotations.outline.strokeWidth + theme.annotations.outline.outlineWidth * 2;
      ctx.beginPath();
      ctx.arc(annotation.x, annotation.y, annotation.size / 2, 0, 2 * Math.PI);
      ctx.stroke();
    }
    if (annotation.type === 'dot' && theme.annotations.symbol.outlineWidth > 0) {
      ctx.strokeStyle = theme.annotations.symbol.outlineColor;
      ctx.lineWidth = theme.annotations.symbol.outlineWidth * 2;
      ctx.beginPath();
      ctx.arc(annotation.x, annotation.y, annotation.size / 2, 0, 2 * Math.PI);
      ctx.stroke();
    }
    if (annotation.type === 'rect' && theme.annotations.outline.outlineWidth > 0) {
      ctx.strokeStyle = theme.annotations.outline.outlineColor;
      ctx.lineWidth = theme.annotations.outline.strokeWidth + theme.annotations.outline.outlineWidth * 2;
      ctx.beginPath();
      ctx.rect(annotation.x - annotation.width / 2, annotation.y - annotation.height / 2, annotation.width, annotation.height);
      ctx.stroke();
    }
    ctx.strokeStyle = theme.annotations.link.stroke;
    ctx.lineWidth = theme.annotations.link.strokeWidth;
    ctx.beginPath();
    drawPoints(ctx, annotation.computed.points);
    ctx.stroke();
    if (annotation.type === 'circle') {
      ctx.strokeStyle = theme.annotations.outline.stroke;
      ctx.lineWidth = theme.annotations.outline.strokeWidth;
      ctx.beginPath();
      ctx.arc(annotation.x, annotation.y, annotation.size / 2, 0, 2 * Math.PI);
      ctx.stroke();
    }
    if (annotation.type === 'dot') {
      ctx.fillStyle = theme.annotations.symbol.fill;
      ctx.beginPath();
      ctx.arc(annotation.x, annotation.y, annotation.size / 2, 0, 2 * Math.PI);
      ctx.fill();
    }
    if (annotation.type === 'rect') {
      ctx.strokeStyle = theme.annotations.outline.stroke;
      ctx.lineWidth = theme.annotations.outline.strokeWidth;
      ctx.beginPath();
      ctx.rect(annotation.x - annotation.width / 2, annotation.y - annotation.height / 2, annotation.width, annotation.height);
      ctx.stroke();
    }
    if (typeof annotation.note === 'function') {
      annotation.note(ctx, {
        datum: annotation.datum,
        x: annotation.computed.text[0],
        y: annotation.computed.text[1],
        theme: theme
      });
    } else {
      ctx.font = "".concat(theme.annotations.text.fontSize, "px ").concat(theme.annotations.text.fontFamily);
      ctx.fillStyle = theme.annotations.text.fill;
      ctx.strokeStyle = theme.annotations.text.outlineColor;
      ctx.lineWidth = theme.annotations.text.outlineWidth * 2;
      if (theme.annotations.text.outlineWidth > 0) {
        ctx.lineJoin = 'round';
        ctx.strokeText(annotation.note, annotation.computed.text[0], annotation.computed.text[1]);
        ctx.lineJoin = 'miter';
      }
      ctx.fillText(annotation.note, annotation.computed.text[0], annotation.computed.text[1]);
    }
  });
  ctx.restore();
};

exports.Annotation = Annotation;
exports.annotationSpecPropType = annotationSpecPropType;
exports.bindAnnotations = bindAnnotations;
exports.computeAnnotation = computeAnnotation;
exports.defaultProps = defaultProps;
exports.getLinkAngle = getLinkAngle;
exports.renderAnnotationsToCanvas = renderAnnotationsToCanvas;
exports.useAnnotations = useAnnotations;
exports.useComputedAnnotation = useComputedAnnotation;
exports.useComputedAnnotations = useComputedAnnotations;
