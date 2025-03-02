import 'dart:convert';

import 'package:my_app/model/property.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/GoogleAuth.dart';

class AddExpenseScreen extends StatefulWidget {
  Expense expense;
  bool editMode = false;
  AddExpenseScreen({super.key, required this.expense, required this.editMode});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  bool isFormValid = false; // Tracks if the form is valid
  String _category = 'Tax'; // Default category
  double _amount = 0.0;
  double _rate = 0.0;
  double _balance = 0.0;
  double _payment = 0.0;
  bool isToggled = false;
  bool calculatedField = false;
  DateTime _selectedDate = DateTime.now(); // Default date as current date
  late PropertyModel propertyModel;
  Property? propertyName;
  Unit? propUnit;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    propertyModel = context.watch<PropertyModel>();
    if (this.widget.editMode) {
      setState(() {
        amountController.text = this.widget.expense.amount.toString();
        this.propertyName = propertyModel.getProperty(this.widget.expense.propertyId);
        this._category = this.widget.expense.category;
        _amount = this.widget.expense.amount;
        //editMode = true;
        AutoCalculator ac  = propertyModel.getAutoCalculator(this.widget.expense.propertyId, this._category);
        if (ac != AutoCalculator.nullAC()) {
          calculatedField = true;
          balanceController.text = ac.mapVal['Balance'].toString();
          rateController.text = ac.mapVal['Rate'].toString();
          paymentController.text = ac.mapVal['PaymentAmt'].toString();
          isToggled = true;
        }

      });

    }
  }
  bool unitShow = false;


  final amountController = TextEditingController();
  final balanceController = TextEditingController();
  final rateController = TextEditingController();
  final paymentController = TextEditingController();


  @override
  void dispose() {
    amountController.dispose();
    rateController.dispose();
    balanceController.dispose();
    paymentController.dispose();
    super.dispose();
  }
  void validateForm() {
    setState(() {
      isFormValid = _formKey.currentState?.validate() ?? false;
    });
  }

  double calculateAmount() {
    // Example calculation logic
    return _amount; // Replace with your formula
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Expense"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          onChanged: validateForm, // Trigger validation when the form changes
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // Property Dropdown
                    DropdownButtonFormField<Property>(
                      value: propertyName,
                      items: propertyModel.allProps
                          .map<DropdownMenuItem<Property>>((Property value) {
                        return DropdownMenuItem<Property>(
                          value: value,
                          child: Text(value.name),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: "Property",
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.apartment_outlined)
                      ),
                      validator: (value) =>
                      value == null ? "Please select a property" : null,
                      onChanged: (Property? newValue) {
                          setState(() {
                            propertyName = newValue!;
                          });
                        },
                    ),
                    SizedBox(height: 16),

                    if (propertyName != null && propertyName!.unitIds.length > 1)
                      DropdownButtonFormField<Unit>(
                        value: propUnit,
                        items: getAllUnits(propertyName!)
                            .map<DropdownMenuItem<Unit>>((Unit value) {
                          return DropdownMenuItem<Unit>(
                            value: value,
                            child: Text(value.name),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: "Unit Name",
                          border: OutlineInputBorder(),
                          icon: Icon(Icons.home),
                        ),
                        validator: (value) =>
                        value == null ? "Please select a Unit" : null,
                        onChanged: (value) {
                          setState(() {
                            propUnit = value;
                          });
                        },
                      ),
                    SizedBox(height: 16),
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _category,
                      items: <String>["Tax", "Interest","Property Insurance", "Sewer", "Gas-Heat", "Gas",
                        "Water", "Electric", "Telephone", "Internet", "Pest Control", "Vacancy", "Management", "Supplies",
                        "Bank Fee", "Legal", "Violation", "Landscape",  "Administrative"]
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: "Expense Type",
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.category_outlined)
                      ),
                      validator: (value) =>
                      value == null ? "Please select an Expense" : null,
                      onChanged: (value) {
                        setState(() {
                          _category = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    // Auto Calculation Switch
                    ListTile(
                      title: Text("Auto Calculate Amount"),
                      trailing: Switch(
                        value: isToggled,
                        onChanged: (value) {
                          setState(() {
                            isToggled = value;
                            if (isToggled) {
                              _amount = calculateAmount(); // Auto-calculate
                            } else {
                              _amount = 0; // Reset amount for manual input
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    // Conditional Amount Section
                    if (!isToggled)
                      ListTile(
                        title: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Amount",
                            border: OutlineInputBorder(),
                            icon: Icon(Icons.attach_money)
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter an amount";
                            }
                            final parsedAmount = double.tryParse(value);
                            if (parsedAmount == null || parsedAmount <= 0) {
                              return "Please enter a valid amount";
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _amount = double.tryParse(value!)!;
                          },
                        ),
                      )
                    else
                      ListTile(
                        title: Text(
                          "Calculated Amount: ${_amount.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              AutoCalculator ac  = propertyModel.getAutoCalculator(propertyName!.id, _category);
                              if (ac != AutoCalculator.nullAC()) {
                                calculatedField = true;
                                balanceController.text =
                                    (ac.mapVal['Balance'] as double)
                                        .toStringAsFixed(2);
                                rateController.text =
                                    ac.mapVal['Rate'].toString();
                                paymentController.text =
                                    ac.mapVal['PaymentAmt'].toString();
                              }
                              showPopup(context);
                              //isToggled = false; // Switch to manual mode
                              //_amount = 0; // Clear auto-calculated amount
                            });
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Date picker for transaction date
                    ListTile(
                      title: Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context), // Opens date picker
                    ),
                  ],
                ),
              ),

              // Save Button at the Bottom
              SafeArea(
                child: ElevatedButton(
                  onPressed: isFormValid
                      ? () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();


                      // Create and save transaction
                      final expense = Expense(
                        category: _category,
                        amount: _amount,
                        unitId: propUnit == null? 0 : propUnit!.id,
                        propertyId: propertyName!.id,
                        dateOfExpense: _selectedDate,
                      );
                      //Hive.box('transactions').add(expense);
                      propertyModel.addExpense(expense);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Expense saved successfully!")),
                      );
                    }
                  }
                      : null, // Disable button if form is invalid
                  child: Text("Save"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // Full-width button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Rectangular shape
                    ),
                  ),
                ),

              ),
              this.widget.editMode ?
              ElevatedButton.icon(
                onPressed: () {

                  propertyModel.removeExpense(this.widget.expense);
                  // Reset form after submission

                  ScaffoldSnackbar.of(context).show('Expense deleted');
                  setState(() { _category = 'Tax';
                  _amount = 0.0;
                  isToggled = false;
                  _selectedDate = DateTime.now();
                  this.widget.editMode = false;
                  this.widget.expense = Expense.nullExpense();});

                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Red background color
                  minimumSize: Size(double.infinity, 50),// Button dimensions
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Rectangular shape
                  ),
                ),
              )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }



  void showPopup(BuildContext context) {
    String title = "Interest ${_amount.toStringAsFixed(2)}";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Interest Formula'),
          content: Container(width: 200, height: 350, decoration: const BoxDecoration(color: Colors.white10), child: Column(
            children: [
              SizedBox(height: 15,),
              SizedBox(
                width: 300,
                height: 50,
                child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Balance',
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount'; // Validate amount
                      }
                      return null;
                    },
                    onSaved: (value) => _balance = double.parse(value!),
                    controller: balanceController),
              ),
              SizedBox(height: 15,),
              SizedBox(
                width: 300,
                height: 50,
                child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Rate',
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.percent),

                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a rate%'; // Validate amount
                      }
                      return null;
                    },
                    onSaved: (value) => _rate = double.parse(value!),
                    controller: rateController),
              ),
              SizedBox(height: 15,),
              SizedBox(
                width: 300,
                height: 50,
                child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Payment Amount',
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount'; // Validate amount
                      }
                      return null;
                    },
                    onSaved: (value) => _payment = double.parse(value!),
                    controller: paymentController),
              ),
              SizedBox(height: 8,),
              SizedBox(
                width: 300,
                height: 50,
                child: TextFormField(
                  enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'New Interest Amount',
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    //onSaved: (value) => _payment = double.parse(value!),
                    controller: amountController),

              ),
              SizedBox(height: 8,),

              Center(
                child: Row(
                  children: [
                ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        Map<String, dynamic> acMap = {};
                        DateTime today = DateTime.now();
                        acMap['Balance'] = balanceController.text;
                        acMap['Rate'] = rateController.text;
                        acMap['PaymentAmt'] = paymentController.text;
                        propertyModel.addAutoCalculator(AutoCalculator(calculatorType: "Interest", propertyId: propertyName!.id,dateOfEvent: DateTime(today.year, today.month, 1),
                            activeFlag: true, frequency: 1, mapVal: acMap));

                      });
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        )
                    )
                ),
                SizedBox(width: 5,),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _amount = (double.parse(balanceController.text) * double.parse(rateController.text)*.01/12);
                      amountController.text = _amount.toStringAsFixed(2);

                    });
                  },
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calculate'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    )
                  )
                ),
                  ]),
              )
            ],
          ),),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
  // Date picker function
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked; // Update selected date
      });
    }
  }

  Container addUnitDropDown() {
    Container retVal = Container();
    if (propertyName != null && propertyName!.unitIds.length > 1) {
      retVal = Container(
          child:Column(
            children: [
              SizedBox(height: 16,),
              DropdownButtonFormField<Unit>(
                      value: propUnit,
                      decoration: const InputDecoration(
              labelText: 'Unit',
              border: OutlineInputBorder(),
              icon: Icon(Icons.apartment),
                      ),
                      onChanged: (Unit? value) {
              setState(() {
                propUnit = value!;

              });
                      },
                      items: getAllUnits(propertyName!)
                .map<DropdownMenuItem<Unit>>((Unit value) {
              return DropdownMenuItem<Unit>(
                value: value,
                child: Text(value.name),
              );
                      }).toList(),
                    ),
            ],
          ),);
    }
    return retVal;
  }
  
  List<Unit> getAllUnits(Property prop) {
    List<Unit> retVal = [];
    prop.unitIds.forEach((element) {retVal.add(propertyModel.getUnit(element));});
    return retVal;
  }

}


/* Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(
        onPressed: () => Navigator.of(context).pop(),
      ),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Form with validation
          child: ListView(
            children: [
              const SizedBox(height: 32,),
              DropdownButtonFormField<Property>(
                value: propertyName,
                decoration: const InputDecoration(
                  labelText: 'Property',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.apartment),
                ),
                onChanged: (Property? newValue) {
                  setState(() {
                    propertyName = newValue!;
                                      });
                },
                items: propertyModel.allProps
                    .map<DropdownMenuItem<Property>>((Property value) {
                  return DropdownMenuItem<Property>(
                    value: value,
                    child: Text(value.name),
                  );
                }).toList(),
              ),
              unitShow?  addUnitDropDown() : Container(),

              const SizedBox(height: 16,),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.category),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _category = newValue!;

                  });
                },
                items: <String>["Tax", "Interest","Property Insurance", "Sewer", "Gas-Heat", "Gas",
                  "Water", "Electric", "Telephone", "Internet", "Pest Control", "Vacancy", "Management", "Supplies",
                      "Bank Fee", "Legal", "Violation", "Landscape",  "Administrative"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              showIssue? getIssueContent() : Container(),
              const SizedBox(height: 16),
              // Input for transaction amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: 140,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(),
                            icon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (value) => _amount = double.parse(value!),
                          controller: amountController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount'; // Validate amount
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    // Switch for Income/Expense selection
                    Expanded(

                      child: SizedBox(
                        width: 70,
                        child: SwitchListTile(
                          title: isToggled ? const Text('Auto Off') : const Text("Auto On"),
                          value: calculatedField,
                          onChanged: (bool value) {
                            setState(() {
                              calculatedField = value;
                              if (calculatedField) {
                                AutoCalculator ac  = propertyModel.getAutoCalculator(propertyName!.id, this._category);
                                if (ac != AutoCalculator.nullAC()) {
                                  calculatedField = true;
                                  balanceController.text = (ac.mapVal['Balance'] as double).toStringAsFixed(2);
                                  rateController.text = ac.mapVal['Rate'].toString();
                                  paymentController.text = ac.mapVal['PaymentAmt'].toString();
                                  showPopup(context);
                                }
                              }
                            });
                          },
                          //secondary: Icon(
                          // _isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                          // color: _isIncome ? Colors.green : Colors.red,
                          //),

                        ),
                      ),
                    ),
                    Switch(
                      value: isToggled,
                      onChanged: (value) {
                        setState(() {
                          isToggled = value; // Toggle the state
                        });
                      },
                      activeColor: Colors.green, // Color when switched on
                      inactiveThumbColor: Colors.red, // Color when switched off

                    )
        ],
                ),

              const SizedBox(height: 16),

              // Dropdown for selecting category



              if (calculatedField)            //Your popup widget
                Container(width: 200, height: 255, decoration: const BoxDecoration(color: Colors.white10), child: Column(
                  children: [
                    SizedBox(height: 15,),
                      SizedBox(
                        width: 300,
                        height: 50,
                        child: TextFormField(
                        decoration: const InputDecoration(
                        labelText: 'Balance',
                          border: OutlineInputBorder(),
                          icon: Icon(Icons.attach_money),
                        ),
                          keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an amount'; // Validate amount
                              }
                              return null;
                            },
                          onSaved: (value) => _balance = double.parse(value!),
                          controller: balanceController),
                      ),
                    SizedBox(height: 15,),
                    SizedBox(
                      width: 300,
                      height: 50,
                      child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Rate',
                            border: OutlineInputBorder(),
                            icon: Icon(Icons.percent),

                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a rate%'; // Validate amount
                            }
                            return null;
                          },
                          onSaved: (value) => _rate = double.parse(value!),
                          controller: rateController),
                    ),
                    SizedBox(height: 15,),
                    SizedBox(
                      width: 300,
                      height: 50,
                      child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Payment Amount',
                            border: OutlineInputBorder(),
                            icon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount'; // Validate amount
                            }
                            return null;
                          },
                          onSaved: (value) => _payment = double.parse(value!),
                          controller: paymentController),
                    ),
                  SizedBox(height: 8,),
                  ElevatedButton.icon(onPressed: () { setState(() {amountController.text = (double.parse(balanceController.text) * double.parse(rateController.text)*.01/12).toStringAsFixed(2);

                  }); },
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calculate'),

                  ),
                  ],
                ),),
              const SizedBox(height: 16),

              // Date picker for transaction date
              ListTile(
                title: Text(
                  'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context), // Opens date picker
              ),
              const SizedBox(height: 16),

              // Button to add the transaction
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save(); // Save form data

                    // Create and save transaction
                    final expense = Expense(
                      category: _category,
                      amount: _amount,
                      unitId: propUnit == null? 0 : propUnit!.id,
                      propertyId: propertyName!.id,
                      dateOfExpense: _selectedDate,
                    );
                    if (_category == "Repair") expense.issueId = issue!.id;
                    //Hive.box('transactions').add(expense);
                    propertyModel.addExpense(expense);
                    if (calculatedField) {
                      Map<String, dynamic> acMap = {};
                      DateTime today = DateTime.now();
                      acMap['Balance'] = balanceController.text;
                      acMap['Rate'] = rateController.text;
                      acMap['PaymentAmt'] = paymentController.text;
                      propertyModel.addAutoCalculator(AutoCalculator(calculatorType: "Interest", propertyId: propertyName!.id,dateOfEvent: DateTime(today.year, today.month, 1),
                          activeFlag: true, frequency: 1, mapVal: acMap));
                    }
                    // Reset form after submission
                    _category = 'Tax';
                    _amount = 0.0;
                    calculatedField = false;
                    _selectedDate = DateTime.now();
                    this.widget.editMode = false;
                    ScaffoldSnackbar.of(context).show('Expense updated');
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Save Expense'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              this.widget.editMode ?
                ElevatedButton.icon(
                  onPressed: () {

                      propertyModel.removeExpense(this.widget.expense);
                      // Reset form after submission

                      ScaffoldSnackbar.of(context).show('Expense deleted');
                      setState(() { _category = 'Tax';
                      _amount = 0.0;
                      calculatedField = false;
                      _selectedDate = DateTime.now();
                      this.widget.editMode = false;
                      this.widget.expense = Expense.nullExpense();});

                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Expense'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                )
              : Container(),
            ],
          ),
        ),
      ),
    );
  }*/