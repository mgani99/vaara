import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/model/property.dart';


class DatabaseService {

  static const PROPERTY_REF="Reapp/properties";
  static const RENTABLE_REF="Reapp/rentables";
  static const TENANTS_REF="Reapp/tenants";
  static const UNIT_REF="Reapp/unit";
  static const LEASEDETAILS_REF="Reapp/leaseDetails";
  static const TRANSACTIONS_REF="Reapp/transactions";
  static const ISSUE_REF="Reapp/issues";
  static const CONTRACTORS_REF="Reapp/contractors";
  static const TX_MONTH_REF = "Reapp/currentMonth";//mm/yy
  static const TX_SUMMARY_BY_MONTH = "Reapp/txSummary/";

  static const EXPENSE_REF = "Reapp/expenses";

  static Future<List<Property>> getProperties() async {
    final List<Property> retVal = [];
    final snapshot = await FirebaseDatabase.instance.ref(DatabaseService.PROPERTY_REF).get();
    if (snapshot.value == null) return [];
    final map = snapshot.value as Map<dynamic, dynamic>;
    map.forEach((key, value) {
      final property = Property.fromMap(value);
      retVal.add(property);
    });
    return retVal;
  }

  static Future<List<RentableModel>> getRentables() async {
    final List<RentableModel> retVal = [];
    try {
      final snapshot = await FirebaseDatabase.instance.ref(DatabaseService.RENTABLE_REF).get();
      final map = snapshot.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        final rentables = RentableModel.fromMap(value);
        retVal.add(rentables);
      });
      return retVal;
    }

    catch(e) {
      print(e);
      return [];
    }

  }

  static Future<List<Unit>> getUnits() async {
    final List<Unit> retVal = [];
    final snapshot = await FirebaseDatabase.instance.ref(DatabaseService.UNIT_REF).get();
    final map = snapshot.value as Map<dynamic, dynamic>;
    map.forEach((key, value) {
      final unit = Unit.fromMap(value);
      retVal.add(unit);
    });
    return retVal;
  }

  static Future<List<Tenant>> getTenants() async {
    final List<Tenant> retVal = [];
    final snapshot = await FirebaseDatabase.instance.ref(DatabaseService.TENANTS_REF).get();
    final map = snapshot.value as Map<dynamic, dynamic>;
    map.forEach((key, value) {
      final tenant = Tenant.fromMap(value);
      retVal.add(tenant);
    });
    return retVal;
  }

  static Future<List<LeaseDetails>> getLeaseDetails() async {
    final List<LeaseDetails> retVal = [];
    final snapshot = await FirebaseDatabase.instance.ref(DatabaseService.LEASEDETAILS_REF).get();
    if (snapshot.value == null) return [];
    final map = snapshot.value as Map<dynamic, dynamic>;
    map.forEach((key, value) {
      final leaseDetails = LeaseDetails.fromMap(value);
      retVal.add(leaseDetails);
    });
    return retVal;
  }



  static Future<List<PropertyTransaction>> getTransactions() async {
    final List<PropertyTransaction> retVal = [];

    final snapshot = await FirebaseDatabase.instance.ref(
        DatabaseService.TRANSACTIONS_REF).get();
    if (snapshot.value == null) return [];
    final map = snapshot!.value as Map<dynamic, dynamic>;
    map.forEach((key, value) {
      final tx = PropertyTransaction.fromMap(value);
      retVal.add(tx);
    });

    return retVal;
  }

  static Future<String> getCurrentMonth() async {
    String retVal="";

    await FirebaseDatabase.instance.ref(DatabaseService.TX_MONTH_REF)
        .once()
        .then((snapshot){retVal=snapshot!.snapshot!.value as String;});


    return retVal;
  }

  static Future<List<TransactionSummary>> getTransactionSummary(String currentMonth) async {
    List<TransactionSummary> retVal = [];
    try {
      final snapshot = await FirebaseDatabase.instance.ref(
          DatabaseService.TX_SUMMARY_BY_MONTH + currentMonth).get();
      if (snapshot.value == Null) {
        return [];
      }
      final map = snapshot!.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        final tx = TransactionSummary.fromMap(value);
        retVal.add(tx);
      });
    }
    catch(e) {
      print (e);
      return retVal;
    }

    return retVal;

  }

  static Future<List<Issue>> getIssues() async {
    final List<Issue> retVal = [];


    final snapshot = await FirebaseDatabase.instance.ref(
        DatabaseService.ISSUE_REF).get();
    if (snapshot.value == null) return [];
    final map = snapshot!.value as Map<dynamic, dynamic>;
    map.forEach((key, value) {
      final issue = Issue.fromMap(value);
      retVal.add(issue);
    });

    return retVal;

  }

  static Future<List<Contractor>> getContractors() async{
    final List<Contractor> retVal = [];


    final snapshot = await FirebaseDatabase.instance.ref(
        DatabaseService.CONTRACTORS_REF).get();
    if (snapshot.value == null) return [];
    final map = snapshot!.value as Map<dynamic, dynamic>;
    map.forEach((key, value) {
      final contractor = Contractor.fromMap(value);
      retVal.add(contractor);
    });

    return retVal;
  }

  static Future<List<Expense>> getExpenses() async {
    final List<Expense> retVal = [];


    final snapshot = await FirebaseDatabase.instance.ref(
        DatabaseService.EXPENSE_REF).get();
    if (snapshot.value == null) return [];
    final map = snapshot!.value as Map<dynamic, dynamic>;
    map.forEach((key, value) {
      final expense = Expense.fromMap(value);
      retVal.add(expense);
    });

    return retVal;
  }



}

