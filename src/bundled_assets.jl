# Embedded assets for relocatable PlotlyJS runtimes.

const _PLOTLY_WEBIO_FALLBACK_JS = raw"""
(function (root, factory) {
    if (typeof exports === "object" && typeof module === "object") {
        module.exports = factory();
    } else if (typeof define === "function" && define.amd) {
        define([], factory);
    } else {
        root.PlotlyWebIO = factory();
    }
})(typeof window !== "undefined" ? window : this, function () {
    function hasOwn(obj, key) {
        return obj !== null && obj !== undefined && Object.prototype.hasOwnProperty.call(obj, key);
    }

    function jsType(value) {
        if (Array.isArray(value)) {
            return "Array";
        }
        if (value === null) {
            return "Null";
        }
        return Object.prototype.toString.call(value).slice(8, -1);
    }

    var PlotlyCommands = {
        filterEventData: function (gd, eventData, event) {
            var filteredEventData;
            if (["click", "hover", "selected"].indexOf(event) !== -1) {
                var points = [];

                if (eventData === null || eventData === undefined) {
                    return null;
                }

                var data = gd.data || [];

                for (var i = 0; i < eventData.points.length; i++) {
                    var fullPoint = eventData.points[i];
                    var pointData = {};

                    for (var k in fullPoint) {
                        if (!hasOwn(fullPoint, k)) {
                            continue;
                        }
                        var v = fullPoint[k];
                        var t = jsType(v);
                        if (t !== "Object" && t !== "Array") {
                            pointData[k] = v;
                        }
                    }

                    if (
                        hasOwn(fullPoint, "curveNumber") &&
                        hasOwn(fullPoint, "pointNumber") &&
                        data[pointData.curveNumber] !== undefined &&
                        hasOwn(data[pointData.curveNumber], "customdata")
                    ) {
                        pointData.customdata = data[pointData.curveNumber].customdata[fullPoint.pointNumber];
                    }

                    if (hasOwn(fullPoint, "pointNumbers")) {
                        pointData.pointNumbers = fullPoint.pointNumbers;
                    }

                    points[i] = pointData;
                }

                filteredEventData = { points: points };
            } else if (event === "relayout") {
                filteredEventData = eventData;
            }

            if (hasOwn(eventData, "range")) {
                filteredEventData = filteredEventData || {};
                filteredEventData.range = eventData.range;
            }

            if (hasOwn(eventData, "lassoPoints")) {
                filteredEventData = filteredEventData || {};
                filteredEventData.lassoPoints = eventData.lassoPoints;
            }

            return {
                out: filteredEventData,
                isnil: filteredEventData === null || filteredEventData === undefined,
            };
        },
    };

    function init(WebIO) {
        WebIO.PlotlyCommands = PlotlyCommands;
    }

    return {
        PlotlyCommands: PlotlyCommands,
        init: init,
    };
});
"""

const _bundled_asset_dir = Ref{Union{Nothing, String}}(nothing)
const _plotly_webio_bundle_file = "plotly_webio.bundle.js"
const _plotly_webio_bundle_path_cache = Ref{Union{Nothing, String}}(nothing)

function _write_fallback_bundle()::String
    cached = _plotly_webio_bundle_path_cache[]
    if cached !== nothing && isfile(cached)
        return cached
    end

    dir = _bundled_asset_dir[]
    if dir === nothing
        dir = mktempdir(prefix="plotlyjs-assets-")
        _bundled_asset_dir[] = dir
    end

    path = joinpath(dir, _plotly_webio_bundle_file)
    if !isfile(path) || read(path, String) != _PLOTLY_WEBIO_FALLBACK_JS
        open(path, "w") do io
            write(io, _PLOTLY_WEBIO_FALLBACK_JS)
        end
    end

    _plotly_webio_bundle_path_cache[] = path
    return path
end

function _plotly_webio_bundle_path()::String
    root = pkgdir(PlotlyJS)
    if root !== nothing
        candidate = joinpath(root, "assets", _plotly_webio_bundle_file)
        if isfile(candidate)
            return candidate
        end
    end

    return _write_fallback_bundle()
end
