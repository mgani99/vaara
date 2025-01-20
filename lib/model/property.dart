import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'dart:convert';

import 'package:my_app/services/DatabaseService.dart';


class PropertyModel extends ChangeNotifier {
  /// The private field backing [catalog].

  static final String PAYMENT_DATE_FORMAT="MM/dd/yy hh:mm:ss";
  /// Internal, private state of the cart. Stores the ids of each item.
  List<Property> _properties = [];
  List<Tenant> _allTenants = [];
  List<RentableModel> _allRentables = [];
  List<Unit> _allUnits = [];
  List<LeaseDetails>_allLeaseDetails = [];
  List<PropertyTransaction> _allTxs = [];
  String currentMonth = "";
  List<TransactionSummary> txMap = [];
  List<Issue> _allIssues = [];
  List<Contractor> _allContractors = [];
  List<Expense> _allExpenses = [];

  final database = FirebaseDatabase.instance.ref();

  /// List of items in the cart.
  List<Property> get allProps => _properties;
  List<Tenant> get allTenants => _allTenants;
  List<RentableModel> get allCards => _allRentables;
  List<PropertyTransaction> get allTxs => _allTxs;
  List<Issue> get allIssues => _allIssues;
  List<Contractor> get allContractors => _allContractors;
  List<Expense> get allExpenses => _allExpenses;
  PropertyModel(){
    getPropertyStream();
  }

  /// Adds [item] to cart. This is the only way to modify the cart from outside.
  void add(Property property) async {
    // This line tells [Model] that it should rebuild the widgets that
    int index = _properties.indexOf(property);
    if (index != -1) {
      _properties.remove(property);
      print('removing $property');
    }

    _properties.add(property);
    final dbPropertyReference = database.child('Reapp/properties');
    try {
      await dbPropertyReference.update({'property-id-${property.id}': {'id' : '${property.id}','name' : '${property.name}',
        'address' : '${property.address}','propertyType':'${property.propertyType}','rentalUnits':'${property.unitIds}', 'pictureURL' : '${property.pictureURL}'}});

    }
    catch(e) {
      print('you have error in addng properties ${property.id}');
    }

  }
  /// Adds [item] to cart. This is the only way to modify the cart from outside.
  void addTenant(Tenant tenant) async {
    // This line tells [Model] that it should rebuild the widgets that
    int index = _allTenants.indexOf(tenant);
    if (index != -1) {
      _allTenants.remove(tenant);
      print('removing $tenant');
    }

    _allTenants.add(tenant);
    final dbPropertyReference = database.child('Reapp/tenants');
    try {
      await dbPropertyReference.update({'tenant-id-${tenant.id}': {'id':'${tenant.id}','lastName' : '${tenant.lastName}',
        'firstName' : '${tenant.firstName}','bankAccountId' : '${tenant.bankAccountId}','phoneNumber' : '${tenant.phoneNumber}',
        'email' : '${tenant.email}',}});



    }
    catch(e) {
      print('you haveg ot an error $e');
    }


  }

  Tenant getTenantForTxSummary(TransactionSummary txSummary) {
    Tenant retVal = Tenant.nullTenant();
    RentableModel rm = getRentableModel(txSummary.rentableId);
    if (rm != null) {
      retVal = getTenant(rm.tenantId);
    }
    return retVal;
  }
  void addLeaseDetail(LeaseDetails lease) async {

    int index = _allLeaseDetails.indexOf(lease);
    if (index != -1) {
      _allLeaseDetails.remove(lease);
      print('removing $lease');
    }

    _allLeaseDetails.add(lease);
    final dbPropertyReference = database.child('Reapp/leaseDetails');
    try {
      await dbPropertyReference.update({'leaseDetails-id-${lease.id}': {'id':'${lease.id}','startDate' : '${lease.startDate}',
        'endDate' : '${lease.endDate}','rent' : '${lease.rent}','tenantId' : '${lease.tenantIds}','securityDeposit':'${lease.securityDeposit}',
      }});

    }
    catch(e) {
      print('you Error saving lease details ot an error $e');
    }
  }

  void addUnit(Unit unit) async {
    int index = _allUnits.indexOf(unit);
    if (index != -1) {
      _allUnits.remove(unit);
      print('removing $unit');
    }

    _allUnits.add(unit);
    final dbPropertyReference = database.child('Reapp/unit');
    try {
      await dbPropertyReference.update({'${unit.id}': {'id':'${unit.id}','name' : '${unit.name}',
        'type' : '${unit.unitType}','leaseHistory' : '${unit.leaseHistory}',
        'currentLeaseId' : '${unit.currentLeaseId}','bathrooms' : '${unit.bathrooms}','bedrooms' : '${unit.bedrooms}','livingSpace' : '${unit.livingSpace}',
      }});
      /*await dbPropertyReference.update({'${unit.id}': unit.toJson()});*/

    }
    catch(e) {
      print('you Error saving Unit ot an error $e');
    }

  }
  late StreamSubscription<Property> _streamProperty;
  void getPropertyStream() {
    final dbPropertyReference = database.child('Reapp/properties');

    database.child('Reapp/properties').onValue.listen((event)
    { print('value changed $event');loadPriorityProperties();});

  }

  @override
  void dispose(){
    _streamProperty.cancel();
    super.dispose();
  }


  Future<void> loadPriorityProperties() async {
    currentMonth = DateFormat(PageStatics.DATE_FORMAT).format(DateTime.now()) ;
    currentMonth = await DatabaseService.getCurrentMonth();
    if (currentMonth == null || currentMonth == "") {
      currentMonth = DateFormat(PageStatics.DATE_FORMAT).format(DateTime.now()) ;
    }
    _allRentables = await DatabaseService.getRentables();
    _allRentables.sort();
    _properties = await DatabaseService.getProperties();
    _allUnits = await DatabaseService.getUnits();
    _allContractors = await DatabaseService.getContractors();
    _allTxs = await DatabaseService.getTransactions();
    _allExpenses = await DatabaseService.getExpenses();
    _allIssues = await DatabaseService.getIssues();
    //create map for month based transactions

    setTxMap();
    print('length of txmap*** : ${txMap.length}');
    txMap.sort();
    //txMap.forEach((key, value) => _allTxs.addAll(value ));
    print("length of _allTxs ${_allTxs.length}");

    notifyListeners();
  }

  Future<void> loadOtherProperties() async {

    _allTenants = await DatabaseService.getTenants();
    _allLeaseDetails = await DatabaseService.getLeaseDetails();
    notifyListeners();
  }

  void setTxMap() async {
    txMap= await DatabaseService.getTransactionSummary(currentMonth);
    if (txMap.isEmpty) {
      buildAndSaveTransactionMap(currentMonth);

    }
    txMap.sort();

    notifyListeners();
  }


  void remove(Property prop) {
    _properties.remove(prop);
    // Don't forget to tell dependent widgets to rebuild _every time_
    // you change the model.
    notifyListeners();
  }

  void removeTenant(Tenant tenant) {
    _allTenants.remove(tenant);
    // Don't forget to tell dependent widgets to rebuild _every time_
    // you change the model.
    notifyListeners();
  }

  void rollDate() {
    DateTime dt = DateFormat(PageStatics.DATE_FORMAT).parse(currentMonth);
    dt = DateTime(dt.year, dt.month + 1, dt.day);
    currentMonth = DateFormat(PageStatics.DATE_FORMAT).format(dt);
    txMap.forEach((element) {
      if (element.balance != 0.0) {
        PropertyTransaction tx = PropertyTransaction(debitOrCredit: (element.balance < 0.0 ? PageStatics.CREDIT_FOR_DEBIT_OR_CREDIT : PageStatics.DEBIT_FOR_DEBIT_OR_CREDIT),
            transactionType: PageStatics.ROLL_FOR_PAYMENTTYPEVALUE, rentableId: element.rentableId,
            dateOfTx: DateTime.now(),
            amount: (element.balance < 0 ? element.balance * -1 : element.balance),
            payingMethod: "Zelle", paidBy: 0, balance: element.balance, comment: "Rolled from prior Month");
        addTransaction(tx);
      }
    });
    final dbPropertyReference = database.child('Reapp/');

    try {
      dbPropertyReference.update({'currentMonth': currentMonth});

    }
    catch(e) {
      print('you Error saving Unit ot an error $e');
    }
    //get new transactions set based on the month
    buildAndSaveTransactionMap(currentMonth);
    notifyListeners();
  }



  void addRentables(RentableModel rentables) async{
    int index = allCards.indexOf(rentables);
    if (index != -1) {
      allCards.remove(rentables);
      print('removing $rentables');
    }

    allCards.add(rentables);
    final dbPropertyReference = database.child('Reapp/rentables');
    try {
      //(propName: map['propName'] ?? '', propAddress: map['propAddress'] ?? '', rent: (map['rent']) ?? 0.0 ,
      //         propId: map['propId'] ?? 0, unitName: map['unitName']);
      await dbPropertyReference.update({'rentables-id-${rentables.id}': {'id':'${rentables.id}','propName' : '${rentables.propName}',
        'propAddress' : '${rentables.propAddress}','rent' : '${rentables.rent}','propId' : '${rentables.propId}',
        'unitName' : '${rentables.unitName}', 'unitId' : '${rentables.unitId}', 'leaseDetailsId' : '${rentables.leaseDetailsId}',
        'tenantId' : '${rentables.tenantId}',
        'bathrooms' : '${rentables.bathrooms}',
        'bedrooms' : '${rentables.bedrooms}',
        'livingSpace' : '${rentables.livingSpace}',
        'pictureURL' : '${rentables.pictureURL}'
      }});


    }
    catch(e) {
      print('you Error saving Unit ot an error $e');
    }

    // depend on it.
    notifyListeners();
  }

  List<PropertyTransaction> getTxByRentableId(int rentable) {
    List<PropertyTransaction> retVal = [];
    for (int i=0;i<_allTxs.length;i++) {
      if(allTxs[i].rentableId == rentable) retVal.add(allTxs[i]);
    }
    return retVal;
  }

  void updateTxBalance(PropertyTransaction tx)async{
    //
  }

  void addTransaction(PropertyTransaction tx) async{
    int index = allTxs.indexOf(tx);
    if (index != -1) {
      allTxs.remove(tx);
      print('removing $tx');
    }
    tx.monthAndYear = currentMonth;
    allTxs.add(tx);
    final dbPropertyReference = database.child('Reapp/transactions');
    String formattedDt = DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(tx.dateOfTx);
    try {
      await dbPropertyReference.update({'transaction-id-${tx.id}': {'id':'${tx.id}','debitOrCredit': '${tx.debitOrCredit}','transactionType' : '${tx.transactionType}',
        'rentableId' : '${tx.rentableId}','dateOfTx' : '${formattedDt}','amount' : '${tx.amount}', 'payingMethod': '${tx.payingMethod}',
        'paidBy' : '${tx.paidBy}','balance' : '${tx.balance}','comment':'${tx.comment}','monthAndYear':'${tx.monthAndYear}'}});


    }
    catch(e) {
      print('you Error saving Unit ot an error $e');
    }

    // depend on it.
    notifyListeners();
  }

  Property getProperty(int propId) {
    Property retVal = Property.nullProperty();
    retVal.id = propId;
    final index = _properties.indexOf(retVal);
    if (index != -1) {
      retVal = _properties[index];
    }
    return retVal;
  }

  Tenant getTenant(int tenantId) {
    Tenant retVal = Tenant.nullTenant();
    retVal.id = tenantId;
    final index = _allTenants.indexOf(retVal);
    if (index != -1) {
      retVal = _allTenants[index];
    }
    return retVal;

  }

  Unit getUnit(int unitId) {
    Unit retVal = Unit.nullUnit();
    retVal.id = unitId;
    final index = _allUnits.indexOf(retVal);
    if (index != -1) {
      retVal = _allUnits[index];
    }
    return retVal;
  }

  LeaseDetails getLeaseDetail(int currentLeaseId) {
    LeaseDetails retVal = LeaseDetails.nullLeaseDetails();
    retVal.id = currentLeaseId;
    final index = _allLeaseDetails.indexOf(retVal);
    if (index != -1) {
      retVal = _allLeaseDetails[index];
    }
    return retVal;
  }

  RentableModel getRentableModel(int rentableModelId) {
    RentableModel retVal = RentableModel.nullCardViewModel();
    RentableModel rentable =
        (allCards.where((element) => element.id == rentableModelId)).first;
    if (rentable != null) retVal = rentable;
    return retVal;
  }

  void addTransactionSummary(TransactionSummary tx,String currMonth) async{


    txMap.add(tx);

    final dbPropertyReference = database.child(DatabaseService.TX_SUMMARY_BY_MONTH+currentMonth);
    //String formattedDt = DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(tx.dateOfTx);
    try {
      await dbPropertyReference.update({'transaction-id-${tx.id}': {'id':'${tx.id}','rentableName': '${tx.rentableName}',
        'rent' : '${tx.rent}', 'rentableId' : '${tx.rentableId}','balance' : '${tx.balance}',
        'totalCredit' : '${tx.totalCredit}','totalDebit' : '${tx.totalDebit}','txs' : '${tx.txs}','monthAndYear' : '${tx.monthAndYear}' }});


    }
    catch(e) {
      print('you Error saving Unit ot an error $e');
    }

    // depend on it.
    notifyListeners();
  }


  List<TransactionSummary> buildAndSaveTransactionMap(String forMonth) {
    HashMap<int, TransactionSummary> map = HashMap<int, TransactionSummary>();

    List<TransactionSummary> retVal = [];
    _allTxs.forEach((element) {
      if (forMonth == element.monthAndYear) {
        if (map.containsKey(element.rentableId)) {
          var txSummary = map[element.rentableId];
          if (element.debitOrCredit ==
              PageStatics.CREDIT_FOR_DEBIT_OR_CREDIT ) {
            txSummary?.totalCredit = txSummary.totalCredit + element.amount;
          }
          else
            txSummary?.totalDebit = txSummary.totalDebit+ element.amount;
          txSummary?.balance = txSummary.totalDebit - (txSummary.totalCredit+txSummary.rent) ;
          txSummary?.txs.add(element);
        }
        else {
          RentableModel rentableModel = getRentableModel(element.rentableId);
          TransactionSummary txSummary = TransactionSummary(rentableId: element.rentableId,
              rentableName: rentableModel.propName + "-"+ rentableModel.unitName,
              rent: rentableModel.rent, totalCredit: 0.0, totalDebit: 0.0, balance:rentableModel.rent*-1,monthAndYear: forMonth);

          if (element.debitOrCredit ==
              PageStatics.CREDIT_FOR_DEBIT_OR_CREDIT ) {
            txSummary.totalCredit = txSummary.totalCredit + element.amount;
          }
          else
            txSummary?.totalDebit = element.amount;
          txSummary.balance = txSummary.totalDebit - (txSummary.totalCredit+txSummary.rent) ;
          txSummary?.txs.add(element);
          map.addAll({element.rentableId: txSummary});
        }
      }
    });

    _allRentables.forEach((element) {
      //@todoget the latest rent amount from the leaseDetail based on the date/month
      map.putIfAbsent(element.id, () => TransactionSummary(rentableId: element.id, rentableName: element.propName + "-" + element.unitName ,
          rent: element.rent, totalCredit: 0.0, totalDebit: 0.0, balance: (-1*element.rent),monthAndYear: forMonth));

    });
    map.forEach((key, value) {retVal.add(value);});
    retVal.forEach((element) {addTransactionSummary(element, forMonth);});
    return retVal;
  }

  void removeTransaction(PropertyTransaction tx) async{
    final dbPropertyReference = database.child(DatabaseService.TRANSACTIONS_REF+"//transaction-id-${tx.id}");
    //String formattedDt = DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(tx.dateOfTx);
    try {
      await dbPropertyReference
          .once()
          .then((snapshot){snapshot!.snapshot.ref.remove();});


    }
    catch(e) {
      print('you Error saving Unit ot an error $e');
    }
    allTxs.remove(tx);
    // depend on it.
    notifyListeners();
  }


  void removeContractor(Contractor contractor) async{
    final dbPropertyReference = database.child(DatabaseService.CONTRACTORS_REF+"//contractor-id-${contractor.id}");
    //String formattedDt = DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(tx.dateOfTx);
    try {
      await dbPropertyReference
          .once()
          .then((snapshot){snapshot!.snapshot.ref.remove();});


    }
    catch(e) {
      print('you Error removing Unit ot an error $e');
    }
    allContractors.remove(contractor);
    // depend on it.
    notifyListeners();
  }

  void removeIssue(Issue tx) async{
    final dbPropertyReference = database.child(DatabaseService.ISSUE_REF+"//issue-id-${tx.id}");
    //String formattedDt = DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(tx.dateOfTx);
    try {
      await dbPropertyReference
          .once()
          .then((snapshot){snapshot!.snapshot.ref.remove();});


    }
    catch(e) {
      print('you Error removing Unit ot an error $e');
    }
    allIssues.remove(tx);
    allIssues.sort();
    // depend on it.
    notifyListeners();
  }

  void addIssue(Issue newIssue) async{
    print('saving issue $newIssue');
    int index = allIssues.indexOf(newIssue);
    if (index != -1) {
      allIssues.remove(newIssue);
      print('removing $newIssue');
    }
    allIssues.add(newIssue);
    final dbPropertyReference = database.child(DatabaseService.ISSUE_REF);
    //String formattedDt = DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(newIssue.dateOfIssue);
    try {
      await dbPropertyReference.update({'issue-id-${newIssue.id}': newIssue.toJson()});


    }
    catch(e) {
      print('you Error saving Unit ot an error $e' );
    }
    allIssues.sort();
    // depend on it.
    notifyListeners();
  }

  void addContractor(Contractor contractor) async{
    print('saving contractor $contractor');
    int index = allContractors.indexOf(contractor);
    if (index != -1) {
      allContractors.remove(contractor);
      print('removing $contractor');
    }
    allContractors.add(contractor);
    final dbPropertyReference = database.child(DatabaseService.CONTRACTORS_REF);
    //String formattedDt = DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(newIssue.dateOfIssue);
    try {
      await dbPropertyReference.update({'contractor-id-${contractor.id}': contractor.toJson()});


    }
    catch(e) {
      print('you Error saving Unit ot an error $e' );
    }

    // depend on it.
    notifyListeners();
  }

  LeaseDetails getLeaseDetailsForTxSummary(TransactionSummary tx) {
    LeaseDetails retVal = LeaseDetails.nullLeaseDetails();
    RentableModel rm = getRentableModel(tx.rentableId);
    if (rm != null) {
      retVal = getLeaseDetail(rm.leaseDetailsId);
    }
    return retVal;
  }

  void removeExpense(Expense tx) async{
    final dbPropertyReference = database.child(DatabaseService.EXPENSE_REF+"//expense-id-${tx.id}");
    //String formattedDt = DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(tx.dateOfTx);
    try {
      await dbPropertyReference
          .once()
          .then((snapshot){snapshot!.snapshot.ref.remove();});


    }
    catch(e) {
      print('you Error removing Unit ot an error $e');
    }
    allExpenses.remove(tx);
    allExpenses.sort();
    // depend on it.
    notifyListeners();
  }
  void addExpense(Expense expense) async{
    print('saving Expense $expense');
    int index = allExpenses.indexOf(expense);
    if (index != -1) {
      allExpenses.remove(expense);
      print('removing $expense');
    }
    allExpenses.add(expense);
    final dbPropertyReference = database.child(DatabaseService.EXPENSE_REF);
    //String formattedDt = DateFormatc(PropertyModel.PAYMENT_DATE_FORMAT).format(newIssue.dateOfIssue);
    try {
      await dbPropertyReference.update({'expense-id-${expense.id}': expense.toJson()});


    }
    catch(e) {
      print('you Error saving Unit ot an error $e' );
    }

    // depend on it.
    notifyListeners();
  }

  RentableModel getRentableModelForUnit(int unitId) {
    return _allRentables.where((element) => element.unitId == unitId).isNotEmpty?
      _allRentables.where((element) => element.unitId == unitId).single : RentableModel.nullCardViewModel();

  }


}

@immutable
class Contractor implements Comparable<Contractor>{
  int id =0;
  String lastName = "";
  String firstName = "";
  String email = "";
  String mobilePhone = "";
  String bankAccount = "";

  Contractor({
    required this.firstName,
    required this.lastName,
    required this.mobilePhone}) {
    if (id == 0 || id == 1) {
      id = firstName.hashCode + lastName.hashCode + mobilePhone.hashCode + email.hashCode;
    }

  }


  static Contractor nullContractor() {
    var retVal =  Contractor(firstName: "", lastName: "",mobilePhone :"",);
    return retVal;
  }

  @override
  bool operator ==(Object other) => other is Contractor && other.id == id ;

  @override
  int compareTo(Contractor other) {
    return (firstName + lastName + mobilePhone).compareTo(other.firstName + other.lastName + other.mobilePhone) ;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['id'] = this.id;
    data['firstName'] = this.firstName;
    data['lastName'] = this.lastName;
    data['mobilePhone'] = this.mobilePhone;
    data['email'] = this.email;
    data['bankAccount'] = this.bankAccount;
    return data;
  }

  factory Contractor.fromMap(Map<dynamic,dynamic> map) {

    Contractor retVal = Contractor(firstName: map['firstName'] ?? "", lastName : map['lastName'] ?? "",
        mobilePhone: map['mobilePhone']?? "");
    retVal.id = map['id']??0;
    retVal.email = map['email']??"";
    retVal.bankAccount = map['bankAccount']??"";

    return retVal;

  }
}


@immutable
class Issue implements Comparable<Issue> {

  int id= 0;
  String title = "";
  String description="";
  int rentableId = 0;
  DateTime dateOfIssue = DateTime.now();
  double laborCost=0.0;
  double materialCost = 0.0;
  String status = "";
  int contractorId = 0;
  String paidStatus = ""; //tenant name
  String comment = "";
  List<String> imageUrls=[""];

  Issue({

    required this.title,
    required this.description,
    required this.rentableId,
    required this.dateOfIssue,
    required this.status}) {
    if (id == 0 || id == 1) {
      id = title.hashCode + rentableId.hashCode + dateOfIssue.hashCode ;
    }

  }
  @override
  bool operator ==(Object other) => other is Issue && other.id == id ;

  @override
  int compareTo(Issue other) {

    return (dateOfIssue).compareTo(other.dateOfIssue) ;


  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    String dt = DateFormat("MM/dd/yy hh:mm:ss").format(dateOfIssue);
    data['id'] = this.id;
    data['title'] = this.title;
    data['description'] = this.description;
    data['rentableId'] = this.rentableId;
    data['dateOfIssue'] = dt;
    data['status'] = this.status;
    data['laborCost'] = this.laborCost.toString();
    data['materialCost'] = this.materialCost.toString();
    data['contractorId'] = this.contractorId;
    data['paidStatus'] = this.paidStatus;
    data['comment'] = this.comment;
    data['imageUrls'] = jsonEncode(this.imageUrls);
    return data;
  }

  static Issue nullIssue() {
    var retVal =  Issue(status: "Open",title:"",
      description : "",
      rentableId : 0,
      dateOfIssue: DateTime.now(),);
    return retVal;
  }

  factory Issue.fromMap(Map<dynamic,dynamic> map) {

    Issue retVal = Issue(title: map['title'] ?? "", description : map['description'] ?? "",
        rentableId: map['rentableId']?? 0, dateOfIssue: DateFormat("MM/dd/yy hh:mm:ss").parse(map['dateOfIssue'] ?? DateTime.now()),
        status: map['status']??"");
    retVal.id = map['id']??0;
    retVal.laborCost = double.parse(map['laborCost'])?? 0.0;
    retVal.materialCost = double.parse(map['materialCost'])??0.0;
    retVal.contractorId = map['contractorId']??0;
    retVal.paidStatus = map['paidStatus']??"";
    retVal.comment = map['comment']??"";

    retVal.imageUrls = List<String>.from(json.decode(map['imageUrls']??[]));

    return retVal;

  }
}


@immutable
class Expense implements Comparable<Expense> {

  int id= 0;
  String category = "";
  String description="";
  int unitId = 0;
  int propertyId = 0;
  double amount =0.0;
  DateTime dateOfExpense = DateTime.now();
  String comment = "";
  int issueId=0; //for repair related expenses


  Expense({

    required this.category,
    required this.unitId,
    required this.propertyId,
    required this.amount,
    required this.dateOfExpense,
  }) {
    if (id == 0 || id == 1) {
      id = category.hashCode + unitId.hashCode + dateOfExpense.hashCode + propertyId.hashCode;
    }

  }
  @override
  bool operator ==(Object other) => other is Expense && other.id == id ;

  @override
  int compareTo(Expense other) {

    return (dateOfExpense).compareTo(other.dateOfExpense) ;

  }

   //static final  allCats = ;


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    String dt = DateFormat("MM/dd/yy hh:mm:ss").format(dateOfExpense);
    data['id'] = this.id;
    data['category'] = this.category;
    data['description'] = this.description;
    data['unitId'] = this.unitId;
    data['propertyId'] = this.propertyId;
    data['amount'] = this.amount.toString();
    data['issueId'] = this.issueId;
    data['dateOfExpense'] = dt;
    data['comment'] = this.comment;
    return data;
  }

  static Expense nullExpense() {
    var retVal =  Expense(category: "",
      unitId : 0,amount : 0.0,propertyId : 0,
      dateOfExpense: DateTime.now(),);
    return retVal;
  }

  factory Expense.fromMap(Map<dynamic,dynamic> map) {

    Expense retVal = Expense(category: map['category'] ?? "", amount: double.parse(map['amount'])?? 0.0,
      unitId: map['unitId']?? 0,propertyId: map['propertyId']?? 0, dateOfExpense: DateFormat("MM/dd/yy hh:mm:ss").parse(map['dateOfExpense'] ?? DateTime.now()),
    );
    retVal.id = map['id']??0;

    retVal.comment = map['comment']??"";

    retVal.issueId = map['issueId']??0;
    retVal.description = map['description'];

    return retVal;

  }
}


@immutable
class PropertyTransaction implements Comparable<PropertyTransaction> {
  int id= 0;
  String debitOrCredit = "";
  String transactionType="";
  int rentableId = 0;
  DateTime dateOfTx = DateTime.now();
  double amount=0.0;
  String monthAndYear = DateFormat(PageStatics.DATE_FORMAT).format(DateTime.now()) ;
  String payingMethod =""; //check, zelle, cash
  int paidBy = 0; //tenant name
  double balance = 0.0;
  String comment = "";


  PropertyTransaction({

    required this.debitOrCredit,
    required this.transactionType,
    required this.rentableId,
    required this.dateOfTx,
    required this.amount,
    required this.payingMethod,
    required this.paidBy,
    required this.balance,
    required this.comment}) {
    if (id == 0 || id == 1) {
      id = transactionType.hashCode + dateOfTx.hashCode + amount.hashCode +
          rentableId.hashCode;
    }
    monthAndYear = DateFormat(PageStatics.DATE_FORMAT).format(dateOfTx) ;
  }
  @override
  bool operator ==(Object other) => other is PropertyTransaction && other.id == id ;

  @override
  int compareTo(PropertyTransaction other) {

    return (dateOfTx).compareTo(other.dateOfTx);


  }

  @override
  String toString() {

    String dt = DateFormat("MM/dd/yy hh:mm:ss").format(dateOfTx);
    //String asofdt = DateFormat("MM/dd/yy hh:mm:ss").format(asOfDate);
    return "{\"id\" : \"${this.id}\", \"debitOrCredit\" : \"${this.debitOrCredit}\", \"transactionType\" : \"${this.transactionType}\", \"rentableId\" : \"${this.rentableId}\", \"amount\" : \"${this.amount}\", \"payingMethod\":\"${this.payingMethod}\", \"paidBy\" : \"${this.paidBy}\",\"balance\" : \"${this.balance}\", \"comment\" : \"${this.comment}\",\"monthAndYear\" : \"${this.monthAndYear}\", \"dateOfTx\" : \"${dt}\"}";
  }
  factory PropertyTransaction.fromMap(Map<dynamic,dynamic> map) {

    PropertyTransaction retVal = PropertyTransaction(transactionType: map['transactionType'] ?? "", debitOrCredit : map['debitOrCredit'] ?? "",
        rentableId: int.parse(map['rentableId']??"0")  , dateOfTx: DateFormat("MM/dd/yy hh:mm:ss").parse(map['dateOfTx'] ?? DateTime.now()),
        amount: double.parse(map['amount']??"0.0"), payingMethod: map['payingMethod']??"",
        paidBy : int.parse(map['paidBy']??"0"),comment: map['comment']??"",balance: double.parse(map['balance']??"0.0"));
    retVal.id = int.parse(map['id']??"0");
    retVal.monthAndYear = map['monthAndYear'] ?? DateFormat(PageStatics.DATE_FORMAT).format(retVal.dateOfTx);

    return retVal;

  }

}

@immutable
class TransactionSummary implements Comparable<TransactionSummary>{
  int id = 0;
  final int rentableId;
  final String rentableName;
  final double rent;
  double totalCredit =0.0;
  double totalDebit=0.0;
  double balance =0.0;
  String monthAndYear = "" ; //mmYY
  List<PropertyTransaction> txs = [];
  Map<String, int> tokens = {};


  TransactionSummary({
    required this.rentableId,
    required this.rentableName,
    required this.rent,
    required this.totalCredit,
    required this.totalDebit,
    required this.balance,
    required this.monthAndYear,

  }) {
    if (id == 0 || id == 1) {
      id = rentableName.hashCode;
    }
  }
  @override
  bool operator ==(Object other) => other is TransactionSummary && other.id == id ;

  @override
  int compareTo(TransactionSummary other) {
    return (rentableName).compareTo(other.rentableName);

  }

  factory TransactionSummary.fromMap(Map<dynamic,dynamic> map) {

    TransactionSummary retVal = TransactionSummary(rentableId : int.parse(map['rentableId']??'0'),rentableName: map['rentableName'] ?? "", rent : double.parse(map['rent'] ?? "0.0"), totalDebit: double.parse(map['totalDebit']??"0.0")  , totalCredit: double.parse(map['totalCredit']??"0.0"),balance:double.parse(map['balance']??"0.0"),monthAndYear: map['monthAndYear']);
    retVal.id = int.parse(map['id']??"0");
    List<dynamic> allTxDynamic = List<dynamic>.from(json.decode(map['txs']??[]));
    allTxDynamic.forEach((element) {retVal.txs.add(PropertyTransaction.fromMap(element));});
    if (retVal.rentableName != null) {

      retVal.tokens[retVal.rentableName.toUpperCase()] = 1;
      retVal.tokens.addAll({for (var item in retVal.rentableName.toUpperCase().split("-")) '$item' : 1 });
      retVal.tokens.addAll({for (var item in retVal.rentableName.toUpperCase().split(" ")) '$item' : 1 });
      List<String> subString=[];
      (retVal.tokens.keys.toList()).forEach((element){
        for (int i=2;i<=element.length;i++) {
          subString.add(element.substring(0,i));
        }
      });
      retVal.tokens.addAll({for (var item in subString) '$item' : 1 });
      //print(retVal);
      // return retVal;

    }
    return retVal;

  }

  @override
  String toString() {
    return this.rentableName + " Total Debit " + this.totalDebit.toString() + " Total credit " + this.totalCredit.toString();
  }

}




class RentableModel implements Comparable<RentableModel>{
  int id= 0;
  final String propName;
  final String propAddress;
  double rent = 0.0;
  final int propId;
  final String unitName;
  final int leaseDetailsId;
  final int tenantId;
  final int unitId;
  double adjustment = 0.0;
  String pictureURL = "";
  int bedrooms = 0;
  double bathrooms = 0.0;
  int livingSpace = 0;


  RentableModel({required this.propName,required this.propAddress, required this.rent,
    required this.propId,required this.unitName, required this.leaseDetailsId, required this.tenantId,  required this.unitId }) {
    if (id == 0 || id == 1) {id = propName.hashCode + unitName.hashCode;}


  }
  @override
  bool operator ==(Object other) => other is RentableModel && other.id == id;

  static nullCardViewModel() { return RentableModel(propName: "", propAddress: "",rent: 0.0,propId: 0,unitName: "",
      leaseDetailsId: 0, tenantId: 0, unitId: 0);}

  @override
  int compareTo(RentableModel other) {

    return (propName + unitName).compareTo(other.propName + other.unitName);
    // TODO: implement compareTo
    throw UnimplementedError();
  }

  factory RentableModel.fromMap(Map<dynamic,dynamic> map) {

    RentableModel retVal= RentableModel(propName: map['propName'] ?? '', propAddress: map['propAddress'] ?? '', rent: double.parse(map['rent']) ?? 0.0 ,
        propId: int.parse(map['propId']) ?? 0, unitName: map['unitName']??"", unitId: int.parse(map['unitId']?? "0")??0,
        leaseDetailsId: int.parse(map['leaseDetailsId'])??0, tenantId: int.parse(map['tenantId'])??0);
    retVal.id = int.parse(map['id']);

    retVal.bathrooms = (map.containsKey('bathrooms')) ? double.parse(map['bathrooms']??"0.0") : 0.0;
    retVal.bedrooms = int.parse(map['bedrooms']??"0");
    retVal.livingSpace = int.parse(map['livingSpace']??"0");
    retVal.pictureURL = map['pictureURL'] ??"";
    return retVal;
  }

}

@immutable
class Unit implements Comparable<Unit> {
  int id =0;
  final String name;
  final String unitType; //main, apartment, garage, parking
  final List<int> leaseHistory;
  final int currentLeaseId;
  int bedrooms = 0;
  double bathrooms= 0;
  int livingSpace= 0;


  int unitTypeId=4; //main house is always 0, apartment by default 1, garage 2, parking 3, all other 4;
  String address="";
  double rent = 0.0;
  int propId=0;
  int tenantId=0;
  String pictureURL = "";




  Unit( this.unitType, this.leaseHistory, this.currentLeaseId, this.name){
    if (id ==0 || id==1) id = name.hashCode + unitType.hashCode + currentLeaseId.hashCode;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['id'] = this.id;
    data['name'] = this.name;
    data['unitType'] = this.unitType;
    data['currentLeaseId'] = this.currentLeaseId;
    data['bedrooms'] = this.bedrooms;
    data['bathrooms'] = this.bathrooms;
    data['livingSpace'] = this.livingSpace;
    data['unitTypeId'] = this.unitTypeId;
    data['address'] = this.address;
    data['rent'] = this.rent;
    data['propId'] = this.propId;
    data['tenantId'] = this.tenantId;
    data['leaseHistory'] = jsonEncode(this.leaseHistory);
    data['pictureURL'] = this.pictureURL;
    return data;
  }


  @override
  bool operator ==(Object other) => other is Unit && other.id == id;
  @override
  String toString() {
    String retVal = "{id: $id, name:'$name',unittype:'$unitType'}";
    // TODO: implement toString
    return retVal;
  }

  static Unit nullUnit() {
    return Unit("", [], 0, "");
  }

  @override
  int get hashCode => id;
  static fromMap(Map<dynamic,dynamic> map) {

    var retVal = Unit(
        (map['type']) ?? "", [], int.parse(map['currentLeaseId'] ?? "0"),
        map['name'] ?? "");
    retVal.id = int.parse(map['id'] ?? "0");
    retVal.bathrooms = (map.containsKey('bathrooms'))
        ? double.parse(map['bathrooms'] ?? "0.0")
        : 0;
    retVal.bedrooms = int.parse(map['bedrooms'] ?? "0");
    retVal.livingSpace = int.parse(map['livingSpace'] ?? "0");

    retVal.unitTypeId = map['unitTypeId'] ?? 0;
    retVal.address = map['address'] ?? "";
    //  retVal.rent =  map['rent'] ?? 0.0;
    retVal.propId = map['propId'] ?? 0;
    retVal.tenantId = map['tenantId'] ?? 0;
    retVal.pictureURL = map['pictureURL'] ?? "";




    return retVal;
  }

  @override
  int compareTo(Unit other) {
    // TODO: implement compareTo
    if (this.unitTypeId != other.unitTypeId) return this.unitTypeId.compareTo(other.unitTypeId);
    return name.compareTo(other.name);

  }

}

@immutable
class LeaseDetails {
  int id =0;
  final String startDate;
  final String endDate;
  final List<int> tenantIds;
  final double rent;
  double securityDeposit = 0.0;


  LeaseDetails(this.startDate, this.endDate, this.tenantIds, this.rent, this.securityDeposit) {
    if (id == 0 || id == 1)id = startDate.hashCode + endDate.hashCode+rent.hashCode + (tenantIds.isNotEmpty?[0].hashCode:0);
  }

  @override
  bool operator ==(Object other) => other is LeaseDetails && other.id == id;

  static LeaseDetails fromMap(Map<dynamic,dynamic> map) {
    LeaseDetails retVal = LeaseDetails(map['startDate']??"", map['endDate']??"", List<int>.from(json.decode(map['tenantId'])??[] ),
        double.parse(map['rent']??"0.0"), double.parse(map['securityDeposit']??"0.0"));
    retVal.id = int.parse(map['id']??"0");
    return retVal;

  }
  @override
  int get hashCode => id;
  static LeaseDetails nullLeaseDetails() {return LeaseDetails("", "", [], 0.0,0.0);}

}

@immutable
class Tenant {
  late int id =0;
  final String lastName;
  final String firstName;
  final String bankAccountId;
  final String phoneNumber;
  final String email;
  Map<String, int> tokens = {};

  Tenant(this.lastName, this.firstName, this.bankAccountId, this.phoneNumber, this.email){
    if (id == 0 || id == 1) id = (lastName + firstName + phoneNumber + email).hashCode;
  }
  @override
  bool operator ==(Object other) => other is Tenant && other.id == id;
  @override
  int get hashCode => id;

  static Tenant nullTenant() {
    var retVal =  Tenant("", "", "", "", "");
    return retVal;
  }

  static Tenant fromMap(Map<dynamic,dynamic> map) {
    Tenant retVal = Tenant.nullTenant();
    retVal = Tenant(map['lastName'], map['firstName'], map['bankAccountId'], map['phoneNumber'], map['email']);
    retVal.id = int.parse(map['id']??"0");

    retVal.tokens[retVal.firstName.toUpperCase()] = 1;
    retVal.tokens[retVal.lastName.toUpperCase()] = 1;

    List<String> subString=[];
    (retVal.tokens.keys.toList()).forEach((element){
      for (int i=2;i<=element.length;i++) {
        subString.add(element.substring(0,i));
      }
    });
    retVal.tokens.addAll({for (var item in subString) '$item' : 1 });
    //print(retVal);
    return retVal;
  }

}




@immutable
class Property {
  late int id=0;
  final String name;
  final List<int> unitIds;
  final String address;
  final String propertyType;
  String pictureURL ="";

  Property({required this.name, required this.address, required this.unitIds,required this.propertyType}) {
    if (id ==0 || id == 1)id = name.hashCode + propertyType.hashCode;
  }

  @override
  int get hashCode => id;

  @override
  bool operator ==(Object other) => other is Property && other.id == id;

  @override
  String toString() {
    String retVal = "{id: $id, name:'$name',address:'$address'}";
    // TODO: implement toString
    return retVal;
  }
  Property.nullProperty() :
        name = "",
        address = "",
        unitIds = [],
        propertyType = "";

  factory Property.fromMap(Map<dynamic,dynamic> map) {

    var retVal = Property(name: map['name'] ?? '',
        address: map['address'] ?? '',
        unitIds: List<int>.from(json.decode(map['rentalUnits']) ??[0]) ,
        propertyType: map['propertyType'] ?? '');
    retVal.id = int.parse(map['id']??"0");
    retVal.pictureURL = map.containsKey('pictureURL') ? map['pictureURL'] ?? '' : '';
    return retVal;

  }
}

