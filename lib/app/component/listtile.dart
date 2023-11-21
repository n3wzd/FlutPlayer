import 'package:flutter/material.dart';

import './switch.dart';
import '../style/color.dart';
import './text.dart';
import './slider.dart';

class ListTileMaker {
  static const double listPadding = 16;

  static multiItem(
          {required int index,
          required String text,
          Key? key,
          VoidCallback? onTap,
          bool selected = false}) =>
      ListTile(
        key: key ?? UniqueKey(),
        title: SizedBox(
          height: 60,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextMaker.normal(
              text,
              fontSize: 18,
            ),
          ),
        ),
        minVerticalPadding: 0,
        onTap: onTap,
        selected: selected,
        selectedTileColor: ColorMaker.lightWine,
        tileColor: index % 2 == 1 ? ColorMaker.darkGrey : ColorMaker.black,
        hoverColor: ColorMaker.lightWine,
      );

  static title({required String text}) => ListTile(
        title:
            TextMaker.normal(text, fontSize: 22, fontWeight: FontWeight.bold),
        tileColor: ColorMaker.darkWine,
        minVerticalPadding: listPadding,
      );

  static content(
          {required String title,
          String subtitle = '',
          VoidCallback? onTap,
          Widget? trailing}) =>
      ListTile(
        title: TextMaker.normal(title, fontSize: 18),
        subtitle: TextMaker.normal(subtitle,
            fontSize: 14, color: ColorMaker.grey, allowLineBreak: true),
        onTap: onTap,
        trailing: trailing,
        minVerticalPadding: listPadding,
      );

  static contentSwitch({
    required String title,
    String subtitle = '',
    bool initialValue = false,
    required void Function(bool) onChanged,
  }) {
    bool switchValue = initialValue;
    return content(
      title: title,
      subtitle: subtitle,
      trailing: StatefulBuilder(
        builder: (context, setState) => SwitchMaker.normal(
          value: switchValue,
          onChanged: (bool value) {
            setState(() {
              onChanged(value);
              switchValue = value;
            });
          },
        ),
      ),
    );
  }

  static contentDropDownMenu<T>({
    required String title,
    String subtitle = '',
    required T initialSelection,
    required void Function(T?) onSelected,
    required List<Map> valueList,
  }) {
    T menuValue = initialSelection;
    return Container(
      padding: const EdgeInsets.all(listPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextMaker.normal(title, fontSize: 18),
          const SizedBox(height: 2),
          TextMaker.normal(subtitle,
              fontSize: 14, color: ColorMaker.grey, allowLineBreak: true),
          const SizedBox(height: 12),
          StatefulBuilder(
            builder: (context, setState) => DropdownButton<T>(
              value: menuValue,
              icon: const Icon(Icons.arrow_drop_down),
              onChanged: (T? value) {
                setState(() {
                  if (value != null) {
                    onSelected(value);
                    menuValue = value;
                  }
                });
              },
              isExpanded: true,
              dropdownColor: ColorMaker.darkGrey,
              items:
                  List<DropdownMenuItem<T>>.generate(valueList.length, (index) {
                return DropdownMenuItem<T>(
                    value: valueList[index]['value'],
                    child: TextMaker.normal(valueList[index]['label'],
                        fontSize: 18));
              }),
            ),
          ),
        ],
      ),
    );
  }

  static contentSlider({
    required String title,
    String subtitle = '',
    required double initialValue,
    required double sliderMax,
    double sliderMin = 0,
    int? sliderDivisions,
    bool sliderShowLabel = false,
    required void Function(double) onChanged,
  }) {
    double sliderValue = (sliderMax > initialValue) ? sliderMax : initialValue;
    return Container(
      padding: const EdgeInsets.all(listPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextMaker.normal(title, fontSize: 18),
          const SizedBox(height: 2),
          TextMaker.normal(subtitle,
              fontSize: 14, color: ColorMaker.grey, allowLineBreak: true),
          const SizedBox(height: 12),
          StatefulBuilder(
            builder: (context, setState) => SliderMaker.normal(
              value: sliderValue,
              max: sliderMax,
              min: sliderMin,
              onChanged: (double value) {
                setState(() {
                  onChanged(value);
                  sliderValue = value;
                });
              },
              useOverlayColor: false,
              divisions: sliderDivisions,
              showLabel: sliderShowLabel,
            ),
          ),
        ],
      ),
    );
  }

  static contentRangeSlider({
    required String title,
    String subtitle = '',
    required RangeValues initialValues,
    required double sliderMax,
    double sliderMin = 0,
    int? sliderDivisions,
    bool sliderShowLabel = false,
    required void Function(RangeValues) onChanged,
  }) {
    RangeValues sliderValues = initialValues;
    return Container(
      padding: const EdgeInsets.all(listPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextMaker.normal(title, fontSize: 18),
          const SizedBox(height: 2),
          TextMaker.normal(subtitle,
              fontSize: 14, color: ColorMaker.grey, allowLineBreak: true),
          const SizedBox(height: 12),
          StatefulBuilder(
            builder: (context, setState) => SliderMaker.range(
              values: sliderValues,
              max: sliderMax,
              min: sliderMin,
              onChanged: (RangeValues values) {
                setState(() {
                  onChanged(values);
                  sliderValues = values;
                });
              },
              useOverlayColor: false,
              divisions: sliderDivisions,
              showLabel: sliderShowLabel,
            ),
          ),
        ],
      ),
    );
  }
}
