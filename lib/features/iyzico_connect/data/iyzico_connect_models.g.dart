// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iyzico_connect_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IyzicoSubMerchantStatusDtoImpl _$$IyzicoSubMerchantStatusDtoImplFromJson(
  Map<String, dynamic> json,
) => _$IyzicoSubMerchantStatusDtoImpl(
  hasSubMerchant: json['hasSubMerchant'] as bool,
  isApproved: json['isApproved'] as bool,
  subMerchantKey: json['subMerchantKey'] as String?,
);

Map<String, dynamic> _$$IyzicoSubMerchantStatusDtoImplToJson(
  _$IyzicoSubMerchantStatusDtoImpl instance,
) => <String, dynamic>{
  'hasSubMerchant': instance.hasSubMerchant,
  'isApproved': instance.isApproved,
  'subMerchantKey': instance.subMerchantKey,
};

_$RegisterSubMerchantRequestDtoImpl
_$$RegisterSubMerchantRequestDtoImplFromJson(Map<String, dynamic> json) =>
    _$RegisterSubMerchantRequestDtoImpl(
      contactName: json['contactName'] as String,
      contactSurname: json['contactSurname'] as String,
      email: json['email'] as String,
      gsmNumber: json['gsmNumber'] as String,
      iban: json['iban'] as String,
      legalCompanyTitle: json['legalCompanyTitle'] as String,
      taxOffice: json['taxOffice'] as String,
      taxNumber: json['taxNumber'] as String,
      address: json['address'] as String,
    );

Map<String, dynamic> _$$RegisterSubMerchantRequestDtoImplToJson(
  _$RegisterSubMerchantRequestDtoImpl instance,
) => <String, dynamic>{
  'contactName': instance.contactName,
  'contactSurname': instance.contactSurname,
  'email': instance.email,
  'gsmNumber': instance.gsmNumber,
  'iban': instance.iban,
  'legalCompanyTitle': instance.legalCompanyTitle,
  'taxOffice': instance.taxOffice,
  'taxNumber': instance.taxNumber,
  'address': instance.address,
};
