import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserEntity {
  final bool isPlus;

  UserEntity({required this.isPlus});

  UserEntity copyWith({
    bool? isPlus,
  }) {
    return UserEntity(
      isPlus: isPlus ?? this.isPlus,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isPlus': isPlus,
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      isPlus: map['isPlus'] as bool,
    );
  }
}

class UserController {
  static final user = ValueNotifier<UserEntity>(
    UserEntity(isPlus: false),
  );
  static void setUser(UserEntity userEntity) async {
    user.value = userEntity;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPlus', userEntity.isPlus);
  }

  static UserEntity get userValue => user.value;
}
