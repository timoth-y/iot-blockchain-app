import 'package:chainmetric/controllers/requirements_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chainmetric/controllers/references_adapter.dart';
import 'package:chainmetric/model/metric_model.dart';
import 'package:chainmetric/model/requirements_model.dart';
import 'package:chainmetric/shared/utils.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:multi_select_flutter/bottom_sheet/multi_select_bottom_sheet_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';

class RequirementsForm extends StatefulWidget {
  final Requirements model;

  const RequirementsForm({this.model});

  @override
  _RequirementsFormState createState() => _RequirementsFormState(model);
}

class _RequirementsFormState extends State<RequirementsForm> {
  Requirements requirements;
  ScrollController _controller = new ScrollController();
  final _formKey = GlobalKey<FormState>();

  _RequirementsFormState(Requirements state) {
    this.requirements = state;
  }

  String get periodStr =>
      "${requirements.periodDuration.inHours}h ${requirements.periodDuration
          .inMinutes - requirements.periodDuration.inHours * 60}m ${requirements
          .periodDuration.inSeconds -
          requirements.periodDuration.inMinutes * 60}s";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Assign requirements"),
      ),
      body: Form(
        key: _formKey,
        child: Scrollbar(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Theme
                                .of(context)
                                .cardColor,
                            boxShadow: kElevationToShadow[1],
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                          child: Column(
                            children: [
                              Padding(padding: EdgeInsets.all(10.0),
                                  child: Row(
                                    children: [
                                      Text("Period"),
                                      Spacer(),
                                      TextButton(
                                        child: Text("$periodStr"),
                                        onPressed: () =>
                                            showPeriodPicker(context),
                                      )
                                    ],
                                  )),
                              MultiSelectBottomSheetField(
                                initialValue:
                                requirements.metrics.keys.toList(),
                                title: Text("Metrics"),
                                buttonText: Text("Select metrics"),
                                listType: MultiSelectListType.CHIP,
                                chipColor: Colors.teal.shade800,
                                selectedColor: Colors.teal,
                                selectedItemsTextStyle: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                buttonIcon: Icon(Icons.add),
                                items: References.metrics
                                    .where((metric) =>
                                !requirements.metrics
                                    .containsKey(metric.name))
                                    .map((metric) =>
                                    MultiSelectItem(
                                      metric.metric,
                                      metric.name,
                                    ))
                                    .toList(),
                                onSelectionChanged: (value) {
                                  setState(() =>
                                      requirements.metrics
                                          .addEntries(value.map((metric) =>
                                          MapEntry(
                                              metric, References.defaultRequirements[
                                              metric]))
                                      )
                                  );
                                },
                                onConfirm: (selected) => setState(() {
                                  var toRemoveKeys = <String>[];
                                  for (var metric in requirements.metrics.keys) {
                                    if (!selected.contains(metric)) {
                                      toRemoveKeys.add(metric);
                                    }
                                  }

                                  for (var key in toRemoveKeys) {
                                    requirements.metrics.remove(key);
                                  }
                                })
                              ),
                            ],
                          ),
                        ),
                        ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(vertical: 6),
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: _controller,
                          children: requirements.metrics.entries.map(
                                  (kvp) =>
                                  SafeArea(
                                      top: false,
                                      bottom: false,
                                      child: Hero(
                                          tag: kvp.key,
                                          child: _requirementControl(
                                              References.metricsMap[kvp.key],
                                              kvp.value)))).toList(),

                        ),
                        SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: decorateWithLoading(context, _submit),
                              child: const Text("SUBMIT REQUIREMENTS",
                                  style: TextStyle(fontSize: 20)),
                            )),
                      ].expand((widget) =>
                      [
                        widget,
                        SizedBox(
                          height: 24,
                        )
                      ])
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _requirementControl(Metric metric, Requirement req) =>
      Card(
        elevation: 5,
        child: Container(
          height: 125,
          child: Padding(
            padding: EdgeInsets.only(top: 10, right: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 5),
                  child: Stack(fit: StackFit.expand,
                      children: [
                    Text(metric.name,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: <Widget>[
                        Flexible(child: TextFormField(
                          initialValue: req.minLimit.toString(),
                          decoration: InputDecoration(
                              filled: true,
                              labelText: "Min",
                              suffixText: metric.unit.trim()),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() => req.minLimit = num.parse(value));
                          },
                        )),
                      SizedBox(width: 10,),
                        Flexible(child: TextFormField(
                          initialValue: req.maxLimit.toString(),
                          decoration: InputDecoration(
                              filled: true,
                              labelText: "Max",
                              suffixText: metric.unit),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() => req.maxLimit = num.parse(value));
                          },
                        ))
                      ],
                    )
                  ])),
            ),
          ),
        ),
      );

  void showPeriodPicker(BuildContext context) {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) =>
          Container(
            height: 300,
            child: CupertinoTimerPicker(
              initialTimerDuration: requirements.periodDuration,
              minuteInterval: 1,
              onTimerDurationChanged: (value) =>
                  setState(() => requirements.period = value.inSeconds),
            ),
          ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState.validate()) {
      try {
        if (await RequirementsController.assignRequirements(requirements)) {
          Navigator.pop(context);
        }
      } on Exception catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
