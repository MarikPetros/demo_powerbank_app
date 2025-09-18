class AuthResponse {
  final RechargeUserEntity rechargeUserEntity;
  final String accessJwt;
  final String refreshJwt;

  AuthResponse({
    required this.rechargeUserEntity,
    required this.accessJwt,
    required this.refreshJwt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      rechargeUserEntity: RechargeUserEntity.fromJson(json['rechargeUserEntity']),
      accessJwt: json['accessJwt'],
      refreshJwt: json['refreshJwt'],
    );
  }
}

class RechargeUserEntity {
  final String id;
  final String phone;
  final String authType;
  final String firstName;
  final String lastName;
  final String email;
  final String createdAt;
  final String updatedAt;
  final String braintreeCustomerId;
  final bool blocked;

  RechargeUserEntity({
    required this.id,
    required this.phone,
    required this.authType,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.braintreeCustomerId,
    required this.blocked,
  });

  factory RechargeUserEntity.fromJson(Map<String, dynamic> json) {
    return RechargeUserEntity(
      id: json['id'],
      phone: json['phone'],
      authType: json['authType'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      braintreeCustomerId: json['braintreeCustomerId'],
      blocked: json['blocked'],
    );
  }
}