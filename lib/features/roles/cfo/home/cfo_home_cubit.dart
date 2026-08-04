import 'package:flutter_bloc/flutter_bloc.dart';

/// ---------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------

enum InvoiceStatus { pending, approved, rejected }

class PendingInvoice {
  const PendingInvoice({
    required this.id,
    required this.vendorName,
    required this.amount,
    required this.dueInDays,
    this.status = InvoiceStatus.pending,
    this.rejectionMessage,
  });

  final String id;
  final String vendorName;
  final double amount;
  final int dueInDays;
  final InvoiceStatus status;
  final String? rejectionMessage;

  PendingInvoice copyWith({
    InvoiceStatus? status,
    String? rejectionMessage,
  }) {
    return PendingInvoice(
      id: id,
      vendorName: vendorName,
      amount: amount,
      dueInDays: dueInDays,
      status: status ?? this.status,
      rejectionMessage: rejectionMessage ?? this.rejectionMessage,
    );
  }
}

class ExpenseCategory {
  const ExpenseCategory({
    required this.label,
    required this.amount,
    required this.shareOfTotal,
  });

  final String label;
  final double amount;
  final double shareOfTotal;
}

class BudgetLine {
  const BudgetLine({
    required this.department,
    required this.actual,
    required this.budgeted,
  });

  final String department;
  final double actual;
  final double budgeted;

  double get progress => budgeted <= 0 ? 0 : (actual / budgeted).clamp(0, 1);
  bool get isOverBudget => actual > budgeted;
}

class FinancialHealth {
  const FinancialHealth({
    required this.updatedAt,
    required this.cashBalance,
    required this.burnRatePerMonth,
    required this.runwayMonths,
    required this.mrr,
  });

  final DateTime updatedAt;
  final double cashBalance;
  final double burnRatePerMonth;
  final double runwayMonths;
  final double mrr;
}

class CfoHomeData {
  const CfoHomeData({
    required this.userInitials,
    required this.userName,
    required this.financialHealth,
    required this.expenseBreakdown,
    required this.pendingInvoices,
    required this.budgetLines,
  });

  final String userInitials;
  final String userName;
  final FinancialHealth financialHealth;
  final List<ExpenseCategory> expenseBreakdown;
  final List<PendingInvoice> pendingInvoices;
  final List<BudgetLine> budgetLines;

  CfoHomeData copyWith({
    String? userInitials,
    String? userName,
    FinancialHealth? financialHealth,
    List<ExpenseCategory>? expenseBreakdown,
    List<PendingInvoice>? pendingInvoices,
    List<BudgetLine>? budgetLines,
  }) {
    return CfoHomeData(
      userInitials: userInitials ?? this.userInitials,
      userName: userName ?? this.userName,
      financialHealth: financialHealth ?? this.financialHealth,
      expenseBreakdown: expenseBreakdown ?? this.expenseBreakdown,
      pendingInvoices: pendingInvoices ?? this.pendingInvoices,
      budgetLines: budgetLines ?? this.budgetLines,
    );
  }
}

/// ---------------------------------------------------------------------
/// State
/// ---------------------------------------------------------------------

abstract class CfoHomeState {
  const CfoHomeState();
}

class CfoHomeInitial extends CfoHomeState {
  const CfoHomeInitial();
}

class CfoHomeLoading extends CfoHomeState {
  const CfoHomeLoading();
}

class CfoHomeLoaded extends CfoHomeState {
  const CfoHomeLoaded(this.data, {this.invoiceActionInFlightId});

  final CfoHomeData data;
  final String? invoiceActionInFlightId;

  CfoHomeLoaded copyWith({
    CfoHomeData? data,
    String? invoiceActionInFlightId,
    bool clearActionInFlightId = false,
  }) {
    return CfoHomeLoaded(
      data ?? this.data,
      invoiceActionInFlightId: clearActionInFlightId
          ? null
          : (invoiceActionInFlightId ?? this.invoiceActionInFlightId),
    );
  }
}

class CfoHomeError extends CfoHomeState {
  const CfoHomeError(this.message);

  final String message;
}

/// ---------------------------------------------------------------------
/// Cubit
/// ---------------------------------------------------------------------

class CfoHomeCubit extends Cubit<CfoHomeState> {
  CfoHomeCubit() : super(const CfoHomeInitial()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    emit(const CfoHomeLoading());
    try {
      final data = await _fetchDashboard();
      emit(CfoHomeLoaded(data));
    } catch (_) {
      emit(const CfoHomeError(
          'Could not load the CFO dashboard. Pull down to retry.'));
    }
  }

  Future<void> refresh() => loadDashboard();

  Future<void> approveInvoice(String invoiceId) async {
    final current = state;
    if (current is! CfoHomeLoaded) return;

    emit(current.copyWith(invoiceActionInFlightId: invoiceId));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final updatedInvoices = current.data.pendingInvoices
          .map((invoice) => invoice.id == invoiceId
              ? invoice.copyWith(status: InvoiceStatus.approved)
              : invoice)
          .toList();
      emit(current.copyWith(
        data: current.data.copyWith(pendingInvoices: updatedInvoices),
        clearActionInFlightId: true,
      ));
    } catch (_) {
      emit(current.copyWith(clearActionInFlightId: true));
    }
  }

  Future<void> rejectInvoice(String invoiceId, {String? reason}) async {
    final current = state;
    if (current is! CfoHomeLoaded) return;

    emit(current.copyWith(invoiceActionInFlightId: invoiceId));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final updatedInvoices = current.data.pendingInvoices
          .map((invoice) => invoice.id == invoiceId
              ? invoice.copyWith(
                  status: InvoiceStatus.rejected, rejectionMessage: reason)
              : invoice)
          .toList();
      emit(current.copyWith(
        data: current.data.copyWith(pendingInvoices: updatedInvoices),
        clearActionInFlightId: true,
      ));
    } catch (_) {
      emit(current.copyWith(clearActionInFlightId: true));
    }
  }

  Future<CfoHomeData> _fetchDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return CfoHomeData(
      userInitials: 'AM',
      userName: 'Aditi Mehra',
      financialHealth: FinancialHealth(
        updatedAt: DateTime.now(),
        cashBalance: 12450000,
        burnRatePerMonth: 1850000,
        runwayMonths: 9.4,
        mrr: 945000,
      ),
      expenseBreakdown: const [
        ExpenseCategory(label: 'Salaries', amount: 4200000, shareOfTotal: 0.38),
        ExpenseCategory(
            label: 'Marketing', amount: 1850000, shareOfTotal: 0.17),
        ExpenseCategory(label: 'SaaS', amount: 980000, shareOfTotal: 0.09),
        ExpenseCategory(
            label: 'Operations', amount: 1620000, shareOfTotal: 0.15),
      ],
      pendingInvoices: const [
        PendingInvoice(
            id: 'inv_1',
            vendorName: 'Apex Logistics',
            amount: 182500,
            dueInDays: 3),
        PendingInvoice(
            id: 'inv_2',
            vendorName: 'Nova Workspace',
            amount: 75500,
            dueInDays: 5),
        PendingInvoice(
            id: 'inv_3',
            vendorName: 'Greenline Media',
            amount: 129000,
            dueInDays: 7),
      ],
      budgetLines: const [
        BudgetLine(department: 'Product', actual: 520000, budgeted: 500000),
        BudgetLine(department: 'Sales', actual: 390000, budgeted: 450000),
        BudgetLine(
            department: 'Customer success', actual: 235000, budgeted: 220000),
      ],
    );
  }
}
