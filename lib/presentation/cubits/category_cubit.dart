import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/financial_notification_service.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import 'cubit_status.dart';

class CategoryState {
  const CategoryState({
    this.status = CubitStatus.initial,
    this.categories = const [],
    this.message,
  });

  final CubitStatus status;
  final List<FinanceCategory> categories;
  final String? message;

  CategoryState copyWith({
    CubitStatus? status,
    List<FinanceCategory>? categories,
    String? message,
  }) {
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      message: message,
    );
  }
}

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(this._repository, this._notifications)
    : super(const CategoryState());

  final CategoryRepository _repository;
  final FinancialNotificationService _notifications;

  Future<void> loadCategories() async {
    emit(state.copyWith(status: CubitStatus.loading));
    try {
      final categories = await _repository.getCategories();
      emit(state.copyWith(status: CubitStatus.success, categories: categories));
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }

  Future<void> saveCategory(FinanceCategory category) async {
    try {
      await _repository.saveCategory(category);
      await loadCategories();
      await _notifyInputSaved(
        'Kategori tersimpan',
        '${category.name} berhasil disimpan.',
      );
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }

  Future<void> _notifyInputSaved(String title, String body) async {
    try {
      await _notifications.showInputSavedNotification(title: title, body: body);
    } catch (_) {
      // Notification failures should not block saved data.
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final inUse = await _repository.isCategoryInUse(id);
      if (inUse) {
        emit(
          state.copyWith(
            status: CubitStatus.failure,
            message:
                'Kategori tidak bisa dihapus karena sudah dipakai transaksi atau anggaran.',
          ),
        );
        return;
      }
      await _repository.deleteCategory(id);
      await loadCategories();
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }
}
