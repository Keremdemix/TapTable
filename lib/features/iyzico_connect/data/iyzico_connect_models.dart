import 'package:freezed_annotation/freezed_annotation.dart';

part 'iyzico_connect_models.freezed.dart';
part 'iyzico_connect_models.g.dart';

@freezed
class IyzicoSubMerchantStatusDto with _$IyzicoSubMerchantStatusDto {
  const factory IyzicoSubMerchantStatusDto({
    required bool hasSubMerchant,
    required bool isApproved,
  }) = _IyzicoSubMerchantStatusDto;

  factory IyzicoSubMerchantStatusDto.fromJson(Map<String, dynamic> json) =>
      _$IyzicoSubMerchantStatusDtoFromJson(json);
}

class RegisterSubMerchantRequestDto {
  final String contactName;
  final String contactSurname;
  final String email;
  final String gsmNumber;
  final String iban;
  final String legalCompanyTitle;
  final String taxOffice;
  final String taxNumber;
  final String address;

  RegisterSubMerchantRequestDto({
    required this.contactName,
    required this.contactSurname,
    required this.email,
    required this.gsmNumber,
    required this.iban,
    required this.legalCompanyTitle,
    required this.taxOffice,
    required this.taxNumber,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
        'contactName': contactName,
        'contactSurname': contactSurname,
        'email': email,
        'gsmNumber': gsmNumber,
        'iban': iban,
        'legalCompanyTitle': legalCompanyTitle,
        'taxOffice': taxOffice,
        'taxNumber': taxNumber,
        'address': address,
      };
}