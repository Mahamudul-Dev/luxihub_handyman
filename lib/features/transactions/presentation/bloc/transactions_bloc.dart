import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luxihub_handyman/features/transactions/domain/usecases/get_transactions.dart';
import 'package:luxihub_handyman/features/transactions/presentation/bloc/transactions_event.dart';
import 'package:luxihub_handyman/features/transactions/presentation/bloc/transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final GetTransactions getTransactions;

  TransactionsBloc({required this.getTransactions}) : super(const TransactionsInitial()) {
    on<TransactionsFetchRequested>(_onFetch);
  }

  Future<void> _onFetch(TransactionsFetchRequested event, Emitter<TransactionsState> emit) async {
    emit(const TransactionsLoading());
    final result = await getTransactions(ProviderIdParams(event.providerId));
    result.fold(
      (f) => emit(TransactionsError(f.message)),
      (transactions) => emit(TransactionsLoaded(transactions)),
    );
  }
}
