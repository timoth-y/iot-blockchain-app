import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:chainmetric/model/asset_model.dart';
import 'package:chainmetric/model/requirements_model.dart';
import 'package:chainmetric/shared/utils.dart';
import 'package:chainmetric/shared/extensions.dart';
import 'package:chainmetric/views/components/svg_icon.dart';
import 'package:chainmetric/controllers/readings_controller.dart';
import 'package:chainmetric/model/metric_model.dart';
import 'package:chainmetric/model/readings_model.dart';
import 'package:chainmetric/controllers/devices_controller.dart';
import 'package:chainmetric/model/device_model.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:charts_flutter/src/text_element.dart'; // ignore: implementation_imports
import 'package:charts_flutter/src/text_style.dart' as style; // ignore: implementation_imports
import 'package:charts_common/src/chart/common/canvas_shapes.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // ignore: implementation_imports

const VIEWPORT_POINTS = 25;

class ReadingsPage extends StatefulWidget {
  final Asset asset;
  final Requirements requirements;
  final bool pageView;
  final int pageIndex;
  final MetricReadings readings;
  final List<Device> devices;

  ReadingsPage({
    this.asset,
    this.requirements,
    this.pageView = false,
    this.pageIndex,
    this.readings,
    this.devices,
  });

  @override
  State<ReadingsPage> createState() => pageView
      ? _ReadingsPageViewState()
      : _ReadingsListViewState();
}

abstract class _ReadingsState extends State<ReadingsPage> {
  MetricReadings readings = MetricReadings();

  final viewportPoints = VIEWPORT_POINTS;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  Map<String, Requirement> get requirements => widget.requirements.metrics;
  List<Device> devicesCache;

  @override
  void initState() {
    super.initState();

    if (widget.readings != null) {
      this.readings = widget.readings;
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => refreshData() );
    }

    if (widget.devices != null) {
      this.devicesCache = widget.devices;
    } else {
      DevicesController.getDevices()
          .then((value) => setState(() => devicesCache = value));
    }
  }

  @protected
  Future refreshData() async {
    refreshKey.currentState?.show();
    return ReadingsController.getReadings(widget.asset.id).then((value) =>
       setState(() => readings = value)
    );
  }

  @protected
  List<charts.Series<MetricReadingPoint, DateTime>> fromReadingsStream(Metric metric, MetricReadingsStream stream) {
    return [
      charts.Series<MetricReadingPoint, DateTime>(
        id: metric.metric,
        displayName: metric.name,
        colorFn: (point, i) => isCritical(stream, i, requirements[metric.metric])
            ? charts.MaterialPalette.red.shadeDefault
            : charts.MaterialPalette.cyan.shadeDefault,
        domainFn: (point, _) => point.timestamp,
        measureFn: (point, _) => point.value,
        data: stream,
      )
    ];
  }

  @protected
  bool meetRequirement(num value, Requirement requirement) =>
      requirement.minLimit <= value && value <= requirement.maxLimit;

  @protected
  bool isCritical(MetricReadingsStream stream, int index, Requirement requirement) =>
    !meetRequirement(stream[index].value, requirement) ||
          (index != stream.length - 1 && !meetRequirement(stream[index + 1].value, requirement));

  @protected
  charts.DateTimeExtents timeViewport(MetricReadingsStream stream) {
    var start = stream.last.timestamp.subtract(widget.requirements.periodDuration * viewportPoints);
    if (start.isBefore(stream.first.timestamp)) start = stream.first.timestamp;
    return charts.DateTimeExtents(
        start: start,
        end: stream.last.timestamp
    );
  }

  @protected
  charts.NumericExtents measureViewport(MetricReadingsStream stream) {
    return charts.NumericExtents(((stream.minValue / 10).floor() * 10) - 10, ((stream.maxValue / 10).ceil() * 10) + 10);
  }
}

class _ReadingsListViewState extends _ReadingsState {
  @override
  int get viewportPoints => 50;

  @override
  Widget build(context) =>
      Scaffold(
          appBar: AppBar(
            title: Text("Metric readings"),
          ),
          body: RefreshIndicator(
            key: refreshKey,
            onRefresh: refreshData,
            child: _chartsListView(context),
          ));


  Widget _chartsListView(BuildContext context) =>
      ListView.builder(
        itemCount: readings.streams?.length ?? 0,
        padding: EdgeInsets.symmetric(vertical: 12),
        itemBuilder: _listBuilder,
      );

  Widget _listBuilder(BuildContext context, int index) {
    var record = readings.streams.entries.elementAt(index);
    return SafeArea(
      child: Hero(
        tag: record.key,
        child: InkWell(
          child: _chartCard(record.key, record.value),
          onTap: () => _openPage(index),
        ),
      ),
    );
  }

  Widget _chartCard(Metric metric, MetricReadingsStream stream) => Card(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
          height: 100,
          child: Stack(
            children: [
              Positioned(
                  left: 8,
                  child: metric.icon()
              ),
              Positioned.fill(
                left: 40,
                child: Text(metric.name, style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)
                ),
              ),
              Positioned(
                right: 8,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("${stream.lastValue}",
                          style: TextStyle(fontSize: 15)
                      ),
                      Text(metric.unit,
                          style: TextStyle(
                              fontSize: 15,
                              color: Theme.of(context).hintColor
                          )
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 80,
                    child: _buildChart(metric, stream)
                ),
              ),
            ],
          )
      ),
    ),
  );

  Widget _buildChart(Metric metric, MetricReadingsStream stream) => charts.TimeSeriesChart(fromReadingsStream(metric, stream),
      animate: true,
      primaryMeasureAxis: charts.NumericAxisSpec(
          showAxisLine: false,
          renderSpec: charts.NoneRenderSpec(
              axisLineStyle: charts.LineStyleSpec(
                  color: charts.MaterialPalette.transparent
              )
          )
      ),
      domainAxis: charts.DateTimeAxisSpec(
          showAxisLine: false,
          viewport: timeViewport(stream),
          renderSpec: charts.NoneRenderSpec(
              axisLineStyle: charts.LineStyleSpec(
                  color: charts.MaterialPalette.transparent
              )
          )
      ),
      defaultRenderer: charts.LineRendererConfig(
        includePoints: false,
        includeArea: true,
        roundEndCaps: true,
        areaOpacity: 0.1,
        strokeWidthPx: 2,
        radiusPx: 2
      ),
    layoutConfig: charts.LayoutConfig(
      bottomMarginSpec: charts.MarginSpec.fixedPixel(0),
      leftMarginSpec: charts.MarginSpec.fixedPixel(0),
      rightMarginSpec: charts.MarginSpec.fixedPixel(0),
      topMarginSpec: charts.MarginSpec.fixedPixel(20),
    ),
    behaviors: [
      charts.LinePointHighlighter(
        defaultRadiusPx: 0,
        showHorizontalFollowLine: charts.LinePointHighlighterFollowLineType.none,
        showVerticalFollowLine: charts.LinePointHighlighterFollowLineType.none,
      )
    ],
    selectionModels: [
      charts.SelectionModelConfig(
        type: charts.SelectionModelType.info,
        changedListener: (_) => _openPage(readings.streams.keys.toList().indexOf(metric))
      )
    ],
  );

  @override
  List<charts.Series<MetricReadingPoint, DateTime>> fromReadingsStream(
      Metric metric,
      MetricReadingsStream stream) => [
      charts.Series<MetricReadingPoint, DateTime>(
        id: metric.metric,
        displayName: metric.name,
        colorFn: (point, i) => isCritical(stream, i, requirements[metric.metric])
            ? charts.MaterialPalette.red.shadeDefault
            : charts.MaterialPalette.cyan.shadeDefault,
        domainFn: (point, _) => point.timestamp,
        measureFn: (point, _) => point.value <= 0 ? 0: point.value,
        data: stream,
      )
    ];

  void _openPage(int index) => openPage(context, ReadingsPage(
    asset: widget.asset,
    requirements: widget.requirements,
    pageView: true,
    pageIndex: index,
    readings: readings,
    devices: devicesCache,
  ));
}

class _ReadingsPageViewState extends _ReadingsState {
  int currentPage;
  bool scrollLocked = false;
  bool animate = true;
  var streamListeners = Map<Metric, CancelReadingsListening>();
  PageController _controller;

  @override
  void initState() {
    super.initState();
    _onPageChanged(widget.pageIndex);
  }

  @override
  Widget build(context) => Scaffold(
      appBar: AppBar(
        title: Text(_currentPageTitle()),
        centerTitle: true,
        toolbarHeight: 50,
        backgroundColor: Theme.of(context).backgroundColor,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop()
        ),
      ),
      body: _chartsPageView(context),
    bottomNavigationBar: Container(
      height: 25,
      child: Align(
        alignment: Alignment.topCenter,
        child: SmoothPageIndicator(
            controller: _controller,
            count: readings.streams?.length ?? 0,
            effect: ExpandingDotsEffect(
              dotColor: Theme.of(context).cardColor,
              activeDotColor: Theme.of(context).accentColor,
              dotHeight: 14,
              dotWidth: 14,
            )
        ),
      ),
    ),
    );

  @override
  void dispose() {
    super.dispose();
    streamListeners.forEach((_, cancel) => cancel());
  }

  Widget _chartsPageView(BuildContext context) => PageView.builder(
    controller: _controller = PageController(
        initialPage: widget.pageIndex,
        viewportFraction: 0.93
    ),
    itemCount: readings.streams?.length ?? 0,
    itemBuilder: _pagerBuilder,
    onPageChanged: _onPageChanged,
    physics: scrollLocked ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
  );

  Widget _pagerBuilder(BuildContext context, int index) {
    var record = readings.streams.entries.elementAt(index);
    return SafeArea(
      child: _chartPage(record.key, record.value),
    );
  }

  Widget _chartPage(Metric metric, MetricReadingsStream stream) => GestureDetector(
      child: Card(
        elevation: 5,
        margin: EdgeInsets.only(left: 4, right: 4, bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        children: [
                          metric.icon(size: 26, color: meetRequirement(stream.lastValue, requirements[metric.metric]) ? Colors.green : Colors.red),
                          SizedBox(width: 5),
                          Text("${stream.lastValue}",
                              style: TextStyle(fontSize: 20, color: meetRequirement(stream.lastValue, requirements[metric.metric]) ? Colors.green : Colors.red)
                          ),
                          Text(metric.unit,
                              style: TextStyle(
                                  fontSize: 20,
                                  color: meetRequirement(stream.lastValue, requirements[metric.metric]) ? Colors.green.withAlpha(160) : Colors.red.withAlpha(160)
                              )
                          ),
                        ],
                      )
                  ),
                  Spacer(),
                  Text(_isActiveStream(metric)
                      ? "Monitoring now"
                      : "Last updated \n${stream.last.timestamp.timeAgoSinceDate()}",
                      style: TextStyle(color: Theme.of(context).hintColor)
                  ),
                  if (_isActiveStream(metric)) ...{
                    SizedBox(width: 5),
                    Icon(Icons.circle, color: Colors.green.withAlpha(160))
                  }
                ],
              ),
              SizedBox(height: 15),
              SizedBox(
                  height: 300,
                  child: _buildChart(metric, stream)),
              SizedBox(height: 15),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Statistics",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)
                  )
              ),
              ListTile(
                  leading: Icon(Icons.trending_up),
                  title: Text("Highest value"),
                  trailing: Text("${stream.maxValue}${metric.unit}")
              ),
              ListTile(
                  leading: Icon(Icons.trending_down),
                  title: Text("Lowest value"),
                  trailing: Text("${stream.minValue}${metric.unit}")
              ),
              ListTile(
                  leading: Icon(Icons.functions),
                  title: Text("Average value"),
                  trailing: Text("${stream.avgValue}${metric.unit}")
              ),
              ListTile(
                  leading: Icon(Icons.rule),
                  title: Text("Compliance index"),
                  trailing: Text("${stream.complianceIndexFor(widget.requirements.metrics[metric.metric])}%")
              ),
              ListTile(
                  leading: SvgIcon("running_with_errors"),
                  title: Text("Critical exposure duration"),
                  trailing: Text(stream.criticalExposureFor(widget.requirements.metrics[metric.metric], widget.requirements.periodDuration).toShortString())
              ),
            ],
          ),
        ),
      ),
      onTapDown:(v) => setState(() {
        animate = false;
        if (v.localPosition.dy < 350) {
          scrollLocked = true;
        } else {
          scrollLocked = false;
        }
      }),
    );

  Widget _buildChart(Metric metric, MetricReadingsStream stream) =>
      charts.TimeSeriesChart(fromReadingsStream(metric, stream),
        animate: animate,
        primaryMeasureAxis: charts.NumericAxisSpec(
            showAxisLine: false,
            renderSpec: charts.GridlineRendererSpec(
              labelStyle: charts.TextStyleSpec(
                fontSize: 10,
                color: toChartColor(Theme.of(context).hintColor),
              ),
              lineStyle: charts.LineStyleSpec(
                thickness: 0,
                color: toChartColor(Theme.of(context).hintColor),
              ),
            ),
            tickFormatterSpec: charts.BasicNumericTickFormatterSpec((v) => "$v${metric.unit}")
        ),
        domainAxis: charts.DateTimeAxisSpec(
            showAxisLine: false,
            viewport: timeViewport(stream),
            renderSpec: charts.GridlineRendererSpec(
                labelStyle: charts.TextStyleSpec(
                  fontSize: 10,
                  color: toChartColor(Theme.of(context).hintColor),
                ),
                lineStyle: charts.LineStyleSpec(
                  thickness: 0,
                  color: toChartColor(Theme.of(context).hintColor),
                )
            )
        ),
        defaultRenderer: charts.LineRendererConfig(
          includePoints: true,
          includeArea: true,
          areaOpacity: 0.1,
          strokeWidthPx: 2,
          radiusPx: 3,
          roundEndCaps: true,
        ),
        behaviors: [
          charts.PanAndZoomBehavior(),
          charts.SlidingViewport(),
          charts.SelectNearest(),
          charts.DomainHighlighter(),
          charts.LinePointHighlighter(
              symbolRenderer: WithTooltipSymbolRenderer(context, metric, devices: devicesCache),
          ),
          charts.RangeAnnotation([
            charts.RangeAnnotationSegment(
                max(requirements[metric.metric].minLimit, measureViewport(stream).min),
                min(requirements[metric.metric].maxLimit, measureViewport(stream).max),
                charts.RangeAnnotationAxisType.measure,
                startLabel: "Min (${requirements[metric.metric].minLimit}${metric.unit})",
                endLabel: "Max (${requirements[metric.metric].maxLimit}${metric.unit})",
                labelStyleSpec: charts.TextStyleSpec(
                  color: toChartColor(Theme.of(context).hintColor),
                ),
                labelAnchor: charts.AnnotationLabelAnchor.end,
                color: charts.Color(r: 12, g: 110, b: 76, a: 100)),
          ], defaultLabelPosition: charts.AnnotationLabelPosition.auto),
        ],
      selectionModels: [
        charts.SelectionModelConfig(
            changedListener: (model) {
              if(model.hasDatumSelection){
                WithTooltipSymbolRenderer.point = stream[model.selectedDatum[0].index];
              }
            }
        )
      ],
    );

  void _onPageChanged(int page) {
    var metric = readings.streams.entries.elementAt(page).key;

    // Updating current page for displaying metric name as title
    setStateWithAnimate(() => currentPage = page);

    if (!streamListeners.containsKey(metric)) {
      ReadingsController.getStream(widget.asset.id, metric.metric)
          .then((value) =>
          setStateWithAnimate(() {
            readings.streams[metric] = value;
          }, animate: false));

      ReadingsController.subscribeToStream(
          widget.asset.id, metric.metric, (point) {
        setStateWithAnimate(() {
          readings.streams[metric].add(point);
        }, animate: false);
      }).then((cancel) => streamListeners[metric] = cancel);
    }
  }

  void setStateWithAnimate(void Function() setter, {bool animate = true}) => setState(() {
      this.animate = animate;
      setter();
    });

  bool _isActiveStream(Metric metric) => DateTime.now().difference(readings.streams[metric].last.timestamp).inSeconds < max(widget.requirements.period * 3, 60);

  String _currentPageTitle() =>
      readings.streams.entries.elementAt(currentPage ?? widget.pageIndex).key.name;
}

class WithTooltipSymbolRenderer extends charts.CircleSymbolRenderer {
  static MetricReadingPoint point;
  final Metric metric;
  final BuildContext context;
  final Map<String, Device> devicesMap;

  WithTooltipSymbolRenderer(this.context, this.metric, {List<Device> devices}):
    this.devicesMap = Map.fromIterable(devices ?? <Device>[], key: (d) => d.id, value: (d) => d);

  @override
  void paint(charts.ChartCanvas canvas, Rectangle<num> bounds, {
      List<int> dashPattern,
      charts.Color fillColor,
      charts.FillPatternType fillPattern,
      charts.Color strokeColor,
      double strokeWidthPx}) {
    if (point == null) return;
    super.paint(canvas, bounds, dashPattern: dashPattern, fillColor: fillColor, strokeColor: strokeColor, strokeWidthPx: strokeWidthPx);
    canvas.drawBarStack(
      CanvasBarStack([
        CanvasRect(Rectangle(bounds.left.round() - 80, bounds.top.round() + 30,
            bounds.width.round() + 160, bounds.height.round() + 85),
            fill: toChartColor(Theme.of(context).primaryColor.withAlpha(180))
          )
        ],
        radius: 12,
        roundBottomLeft: true,
        roundBottomRight: true,
        roundTopLeft: true,
        roundTopRight: true,
        stackedBarPadding: 10
      )
    );
    var textStyle = style.TextStyle();
    textStyle.color = charts.MaterialPalette.teal.shadeDefault;
    textStyle.fontSize = 14;
    canvas.drawText(
        TextElement("Value: ${point.valueRounded}${metric.unit}", style: textStyle),
        (bounds.left - 70).round(),
        (bounds.top + 40).round()
    );
    canvas.drawText(
        TextElement("Time: ${DateFormat("dd-MM h:m:s").format(point.timestamp)}", style: textStyle),
        (bounds.left - 70).round(),
        (bounds.top + 60).round()
    );
    canvas.drawText(
        TextElement("Location: ${point.location.isNotEmpty ? point.location : "Unknown"}", style: textStyle),
        (bounds.left - 70).round(),
        (bounds.top + 80).round()
    );
    if (devicesMap != null && devicesMap.isNotEmpty) {
      canvas.drawText(
          TextElement("Device: ${devicesMap[point.deviceID].name}", style: textStyle),
          (bounds.left - 70).round(),
          (bounds.top + 100).round()
      );
    }
  }
}

charts.Color toChartColor(Color color) =>
    charts.Color(r: color.red, g: color.green, b: color.blue, a: color.alpha);
