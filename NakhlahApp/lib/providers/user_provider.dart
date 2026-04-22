import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class UserState {
  final bool isOtpVerified;
  final AppUser? currentUser;

  UserState({this.isOtpVerified = false, this.currentUser});

  UserState copyWith({bool? isOtpVerified, AppUser? currentUser}) {
    return UserState(
      isOtpVerified: isOtpVerified ?? this.isOtpVerified,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class UserProvider extends ValueNotifier<UserState> {
  UserProvider() : super(UserState(isOtpVerified: false, currentUser: null));

  void setOtpVerified(bool value) {
    this.value = this.value.copyWith(isOtpVerified: value);
  }

  void setCurrentUser(AppUser? user) {
    value = value.copyWith(currentUser: user);
  }

  Future<void> fetchAndSetUser(String uid) async {
    final repo = UserRepository();
    final user = await repo.getUser(uid);
    value = value.copyWith(currentUser: user);
  }
}

final userProvider = UserProvider();
