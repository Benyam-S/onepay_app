import 'package:flutter/material.dart';
import 'package:onepay_app/widgets/basic/dashed.border.dart';


class PasswordFormField extends StatefulWidget {
  final FocusNode focusNode;
  final Function validator;
  final TextEditingController controller;
  final Function onSubmit;

  PasswordFormField(
      {this.focusNode, this.validator, this.controller, this.onSubmit});

  _PasswordFormField createState() => _PasswordFormField();
}

class _PasswordFormField extends State<PasswordFormField> {
  bool visible;

  @override
  void initState() {
    super.initState();
    visible = false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          style: TextStyle(fontSize: 18),
          decoration: InputDecoration(
            border: const DashedInputBorder(),
            labelStyle: TextStyle(color: Theme.of(context).primaryColor),
            labelText: "Password",
          ),
          obscureText: !visible,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmit,
        ),
        Positioned.fill(
          child: Align(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  visible = !visible;
                });
              },
              child: Icon(visible ? Icons.visibility_off : Icons.visibility, size: 28,),
            ),
            alignment: Alignment(0.9, 0),
          ),
        )
      ],
    );
  }
}
