import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/business_photo.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class BusinessPhotosState {
  final List<BusinessPhoto> photos;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const BusinessPhotosState({
    this.photos = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  BusinessPhotosState copyWith({
    List<BusinessPhoto>? photos,
    bool? isLoading,
    bool? isSaving,
    Object? error = _sentinel,
  }) {
    return BusinessPhotosState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

typedef _PhotoKey = ({String tenantId, String businessId});

class BusinessPhotosNotifier
    extends StateNotifier<BusinessPhotosState> {
  BusinessPhotosNotifier(this._ref, this._key)
      : super(const BusinessPhotosState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final _PhotoKey _key;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final photos = await api.getBusinessPhotos(
        businessId: _key.businessId,
      );
      state = BusinessPhotosState(photos: photos);
    } on AgendaApiException catch (e) {
      state = BusinessPhotosState(error: e.message);
    }
  }

  Future<bool> uploadPhoto({
    required List<int> bytes,
    required String fileName,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final photo = await api.uploadBusinessWorkPhoto(
        businessId: _key.businessId,
        bytes: bytes,
        fileName: fileName,
      );
      state = state.copyWith(
        photos: [...state.photos, photo],
        isSaving: false,
      );
      return true;
    } on AgendaApiException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return false;
    }
  }

  Future<bool> addPhoto(String url) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final photo = await api.addBusinessPhoto(
        businessId: _key.businessId,
        url: url,
      );
      state = state.copyWith(
        photos: [...state.photos, photo],
        isSaving: false,
      );
      return true;
    } on AgendaApiException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return false;
    }
  }

  Future<bool> deletePhoto(String photoId) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      await api.deleteBusinessPhoto(
        businessId: _key.businessId,
        photoId: photoId,
      );
      state = state.copyWith(
        photos: state.photos.where((p) => p.id != photoId).toList(),
        isSaving: false,
      );
      return true;
    } on AgendaApiException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return false;
    }
  }
}

final businessPhotosProvider = StateNotifierProvider.autoDispose
    .family<BusinessPhotosNotifier, BusinessPhotosState, _PhotoKey>(
  (ref, key) => BusinessPhotosNotifier(ref, key),
);
