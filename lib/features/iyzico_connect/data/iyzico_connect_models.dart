import 'package:freezed_annotation/freezed_annotation.dart';

part 'iyzico_connect_models.freezed.dart';
part 'iyzico_connect_models.g.dart';

@freezed
class IyzicoSubMerchantStatusDto with _$IyzicoSubMerchantStatusDto {
  const factory IyzicoSubMerchantStatusDto({
    required bool hasSubMerchant,
    required bool isApproved,
    String? subMerchantKey,
  }) = _IyzicoSubMerchantStatusDto;

  factory IyzicoSubMerchantStatusDto.fromJson(Map<String, dynamic> json) =>
      _$IyzicoSubMerchantStatusDtoFromJson(json);
}

@freezed
class RegisterSubMerchantRequestDto with _$RegisterSubMerchantRequestDto {
  const factory RegisterSubMerchantRequestDto({
    required String contactName,
    required String contactSurname,
    required String email,
    required String gsmNumber,
    required String iban,
    required String legalCompanyTitle,
    required String taxOffice,
    required String taxNumber,
    required String address,
  }) = _RegisterSubMerchantRequestDto;

  factory RegisterSubMerchantRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterSubMerchantRequestDtoFromJson(json);
}