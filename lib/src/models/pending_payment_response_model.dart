class PendingPaymentResponseModel {
  final String? merchantId;
  final String? customerPhone;
  final num? amount;
  final String? latestStatus;
  final SavedPaymentOptions? savedPaymentOptions;
  final SelectedPaymentOptions? selectedPaymentOptions;
  final Map<String, dynamic>? cart;
  final List<dynamic>? lineItems;
  final Merchant? merchant;
  final bool? completed;
  final User? user;

  PendingPaymentResponseModel({
    this.merchantId,
    this.customerPhone,
    this.amount,
    this.latestStatus,
    this.savedPaymentOptions,
    this.selectedPaymentOptions,
    this.cart,
    this.lineItems,
    this.merchant,
    this.completed,
    this.user,
  });

  factory PendingPaymentResponseModel.fromJSON({
    required Map<String, dynamic> json,
  }) {
    return PendingPaymentResponseModel(
      merchantId: json['merchantId'] as String?,
      customerPhone: json['customerPhone'] as String?,
      amount: json['amount'] as num?,
      latestStatus: json['latestStatus'] as String?,
      savedPaymentOptions: json['savedPaymentOptions'] != null
          ? SavedPaymentOptions.fromJSON(
              json: json['savedPaymentOptions'] as Map<String, dynamic>)
          : null,
      selectedPaymentOptions: json['selectedPaymentOptions'] != null
          ? SelectedPaymentOptions.fromJSON(
              json: json['selectedPaymentOptions'] as Map<String, dynamic>)
          : null,
      cart: json['cart'] as Map<String, dynamic>?,
      lineItems: json['lineItems'] as List<dynamic>?,
      merchant: json['merchant'] != null
          ? Merchant.fromJSON(json: json['merchant'] as Map<String, dynamic>)
          : null,
      completed: json['completed'] as bool?,
      user: json['user'] != null
          ? User.fromJSON(json: json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (merchantId != null) 'merchantId': merchantId,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (amount != null) 'amount': amount,
        if (latestStatus != null) 'latestStatus': latestStatus,
        if (savedPaymentOptions != null)
          'savedPaymentOptions': savedPaymentOptions!.toJson(),
        if (selectedPaymentOptions != null)
          'selectedPaymentOptions': selectedPaymentOptions!.toJson(),
        if (cart != null) 'cart': cart,
        if (lineItems != null) 'lineItems': lineItems,
        if (merchant != null) 'merchant': merchant!.toJson(),
        if (completed != null) 'completed': completed,
        if (user != null) 'user': user!.toJson(),
      };
}

/// Saved payment options grouped by type.
class SavedPaymentOptions {
  final List<CardOption>? card;
  final List<BankOption>? bank;
  final List<CardOption>? oneTapCardOptions;

  SavedPaymentOptions({
    this.card,
    this.bank,
    this.oneTapCardOptions,
  });

  factory SavedPaymentOptions.fromJSON({required Map<String, dynamic> json}) {
    return SavedPaymentOptions(
      card: json['card'] != null
          ? (json['card'] as List<dynamic>)
              .map((e) => CardOption.fromJSON(json: e as Map<String, dynamic>))
              .toList()
          : null,
      bank: json['bank'] != null
          ? (json['bank'] as List<dynamic>)
              .map((e) => BankOption.fromJSON(json: e as Map<String, dynamic>))
              .toList()
          : null,
      oneTapCardOptions: json['oneTapCardOptions'] != null
          ? (json['oneTapCardOptions'] as List<dynamic>)
              .map((e) => CardOption.fromJSON(json: e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (card != null) 'card': card!.map((c) => c.toJson()).toList(),
        if (bank != null) 'bank': bank!.map((b) => b.toJson()).toList(),
        if (oneTapCardOptions != null)
          'oneTapCardOptions':
              oneTapCardOptions!.map((c) => c.toJson()).toList(),
      };
}

/// Represents a generic card option.
class CardOption {
  final String? bankId;
  final String? institutionCode;
  final String? accountNumber;
  final String? bankName;
  final String? accountName;
  final String? logo;

  const CardOption({
    this.bankId,
    this.institutionCode,
    this.accountNumber,
    this.bankName,
    this.accountName,
    this.logo,
  });

  factory CardOption.fromJSON({
    required Map<String, dynamic> json,
  }) =>
      CardOption(
        bankId: json['bankId'] as String?,
        institutionCode: json['institutionCode'] as String?,
        accountNumber: json['accountNumber'] as String?,
        bankName: json['bankName'] as String?,
        accountName: json['accountName'] as String?,
        logo: json['logo'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (bankId != null) 'bankId': bankId,
        if (institutionCode != null) 'institutionCode': institutionCode,
        if (accountNumber != null) 'accountNumber': accountNumber,
        if (bankName != null) 'bankName': bankName,
        if (accountName != null) 'accountName': accountName,
        if (logo != null) 'logo': logo,
      };

  CardOption copyWith({
    String? bankId,
    String? institutionCode,
    String? accountNumber,
    String? bankName,
    String? accountName,
    String? logo,
  }) {
    return CardOption(
      bankId: bankId ?? this.bankId,
      institutionCode: institutionCode ?? this.institutionCode,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      logo: logo ?? this.logo,
    );
  }

  @override
  String toString() {
    return 'CardOption(bankId: $bankId, institutionCode: $institutionCode, '
        'accountNumber: $accountNumber, bankName: $bankName, '
        'accountName: $accountName, logo: $logo)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardOption &&
          runtimeType == other.runtimeType &&
          bankId == other.bankId &&
          institutionCode == other.institutionCode &&
          accountNumber == other.accountNumber &&
          bankName == other.bankName &&
          accountName == other.accountName &&
          logo == other.logo;

  @override
  int get hashCode =>
      bankId.hashCode ^
      institutionCode.hashCode ^
      accountNumber.hashCode ^
      bankName.hashCode ^
      accountName.hashCode ^
      logo.hashCode;
}

/// Bank-specific payment option.
class BankOption {
  final String? bankName;
  final String? bankId;
  final String? logo;
  final String? accountNumber;
  final String? webLinkAndroid;
  final String? institutionCode;
  final bool? isPrimary;
  final bool? manualPaymentRequired;
  final bool? hasInstantPay;
  final List<String>? primaryInstruments;

  BankOption({
    this.bankName,
    this.bankId,
    this.logo,
    this.accountNumber,
    this.webLinkAndroid,
    this.institutionCode,
    this.isPrimary,
    this.manualPaymentRequired,
    this.hasInstantPay,
    this.primaryInstruments,
  });

  factory BankOption.fromJSON({required Map<String, dynamic> json}) {
    return BankOption(
      bankName: json['bankName'] as String?,
      bankId: json['bankId'] as String?,
      logo: json['logo'] as String?,
      accountNumber: json['accountNumber'] as String?,
      webLinkAndroid: json['webLinkAndroid'] as String?,
      institutionCode: json['institutionCode'] as String?,
      isPrimary: json['isPrimary'] as bool?,
      manualPaymentRequired: json['manualPaymentRequired'] as bool?,
      hasInstantPay: json['hasInstantPay'] as bool?,
      primaryInstruments: json['primaryInstruments'] != null
          ? (json['primaryInstruments'] as List<dynamic>)
              .map((e) => e as String)
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (bankName != null) 'bankName': bankName,
        if (bankId != null) 'bankId': bankId,
        if (logo != null) 'logo': logo,
        if (accountNumber != null) 'accountNumber': accountNumber,
        if (webLinkAndroid != null) 'webLinkAndroid': webLinkAndroid,
        if (institutionCode != null) 'institutionCode': institutionCode,
        if (isPrimary != null) 'isPrimary': isPrimary,
        if (manualPaymentRequired != null)
          'manualPaymentRequired': manualPaymentRequired,
        if (hasInstantPay != null) 'hasInstantPay': hasInstantPay,
        if (primaryInstruments != null)
          'primaryInstruments': primaryInstruments,
      };
}

/// Currently selected payment options.
class SelectedPaymentOptions {
  final OptionAvailable? card;
  final TransferOption? transfer;
  final OptionAvailable? mona;

  SelectedPaymentOptions({
    this.card,
    this.transfer,
    this.mona,
  });

  factory SelectedPaymentOptions.fromJSON(
      {required Map<String, dynamic> json}) {
    return SelectedPaymentOptions(
      card: json['card'] != null
          ? OptionAvailable.fromJSON(json: json['card'] as Map<String, dynamic>)
          : null,
      transfer: json['transfer'] != null
          ? TransferOption.fromJSON(
              json: json['transfer'] as Map<String, dynamic>)
          : null,
      mona: json['mona'] != null
          ? OptionAvailable.fromJSON(json: json['mona'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (card != null) 'card': card!.toJson(),
        if (transfer != null) 'transfer': transfer!.toJson(),
        if (mona != null) 'mona': mona!.toJson(),
      };
}

/// Basic available flag.
class OptionAvailable {
  final bool? available;

  OptionAvailable({this.available});

  factory OptionAvailable.fromJSON({required Map<String, dynamic> json}) {
    return OptionAvailable(available: json['available'] as bool?);
  }

  Map<String, dynamic> toJson() => {
        if (available != null) 'available': available,
      };
}

/// Transfer-specific option with details.
class TransferOption extends OptionAvailable {
  final TransferDetails? details;

  TransferOption({
    super.available,
    this.details,
  });

  factory TransferOption.fromJSON({required Map<String, dynamic> json}) {
    return TransferOption(
      available: json['available'] as bool?,
      details: json['details'] != null
          ? TransferDetails.fromJSON(
              json: json['details'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (available != null) 'available': available,
        if (details != null) 'details': details!.toJson(),
      };
}

/// Details needed for bank transfer.
class TransferDetails {
  final String? accountName;
  final String? bankName;
  final String? accountNumber;
  final String? institutionCode;

  TransferDetails({
    this.accountName,
    this.bankName,
    this.accountNumber,
    this.institutionCode,
  });

  factory TransferDetails.fromJSON({required Map<String, dynamic> json}) {
    return TransferDetails(
      accountName: json['accountName'] as String?,
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      institutionCode: json['institutionCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (accountName != null) 'accountName': accountName,
        if (bankName != null) 'bankName': bankName,
        if (accountNumber != null) 'accountNumber': accountNumber,
        if (institutionCode != null) 'institutionCode': accountNumber,
      };
}

/// Merchant information.
class Merchant {
  final String? name;
  final String? tag;
  final String? image;

  Merchant({
    this.name,
    this.tag,
    this.image,
  });

  factory Merchant.fromJSON({required Map<String, dynamic> json}) {
    return Merchant(
      name: json['name'] as String?,
      tag: json['tag'] as String?,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (tag != null) 'tag': tag,
        if (image != null) 'image': image,
      };
}

/// User profile info.
class User {
  final String? name;
  final String? bvn;
  final String? image;

  User({
    this.name,
    this.bvn,
    this.image,
  });

  factory User.fromJSON({required Map<String, dynamic> json}) {
    return User(
      name: json['name'] as String?,
      bvn: json['bvn'] as String?,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (bvn != null) 'bvn': bvn,
        if (image != null) 'image': image,
      };
}
