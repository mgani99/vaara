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
  String _category = 'Repair'; // Default category
  double _amount = 0.0;
  bool _isIncome = false;
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
        //editMode = true;

      });

    }
  }
  bool unitShow = false;

  Issue? issue;

  bool showIssue = false;

  final amountController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
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
                    showIssue = false;
                    if (newValue.unitIds.length>1) {
                      unitShow = true;
                    }
                    else {
                      unitShow = false;
                      propUnit = propertyModel.getUnit(newValue.unitIds[0]);
                      if (getAllIssues().length>0) showIssue = true;
                    }
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
                    (_category == "Repair" && getAllIssues().length > 0)? showIssue = true : showIssue = false;
                  });
                },
                items: <String>["Repair", "Tax", "Property Insurance", "Sewer",
                  "Water", "Electric", "Telephone", "Internet", "Pest Control", "Vacancy", "Management", "Supplies"
                      "Bank Fee", "Legal", "Violation", "Landscape", "Supplies", "Administrative"]
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
              TextFormField(
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
              const SizedBox(height: 16),

              // Dropdown for selecting category


              // Switch for Income/Expense selection
              SwitchListTile(
                title: const Text('Income'),
                value: _isIncome,
                onChanged: (bool value) {
                  setState(() {
                    _isIncome = value;
                  });
                },
                secondary: Icon(
                  _isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: _isIncome ? Colors.green : Colors.red,
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
                      unitId: propUnit!.id,
                      propertyId: propertyName!.id,
                      dateOfExpense: _selectedDate,
                    );
                    if (_category == "Repair") expense.issueId = issue!.id;
                    //Hive.box('transactions').add(expense);
                    propertyModel.addExpense(expense);
                    // Reset form after submission
                    _category = 'Repair';
                    _amount = 0.0;
                    _isIncome = false;
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
                      setState(() { _category = 'Repair';
                      _amount = 0.0;
                      _isIncome = false;
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

  Container getIssueContent() {
    Container retVal = Container();
    List<Issue> issues = getAllIssues();
    if (issues.length > 1) {
    retVal = Container(child:Column(
      children: [
        SizedBox(height: 16,),
        ListTile(
          title: DropdownButtonFormField<Issue>(
            value: issue,
            decoration: const InputDecoration(
              labelText: 'Issue',
              border: OutlineInputBorder(),
              icon: Icon(Icons.construction),
            ),
            onChanged: (Issue? value) {
              setState(() {
                issue = value!;

                _amount = (value.laborCost + value.materialCost);
                amountController.text = _amount.toString();
                _selectedDate = value.dateOfIssue;

              });
            },
            items:  issues
                .map<DropdownMenuItem<Issue>>((Issue value) {
              return DropdownMenuItem<Issue>(
                value: value,
                child: Text(value.title),
              );
            }).toList(),
          ),
          trailing: TextButton(onPressed: (){print ("Show issue");}, child: Text("Show Issue")),
          onTap: () => _selectDate(context), // Opens date picker
        ),
      ],
    ));}
    else { showIssue = false;}
    return retVal;
  }

  List<Issue> getAllIssues() {
    List<Issue> retVal = [];
    if (propUnit != null) {
        RentableModel rentable = propertyModel.getRentableModelForUnit(propUnit!.id);
        retVal = propertyModel.allIssues.where((element) => element.rentableId == rentable.id).toList();
    }
    return retVal;
  }
}
