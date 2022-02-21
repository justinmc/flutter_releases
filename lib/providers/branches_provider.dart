import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/branches.dart';
import '../models/branch.dart';

class BranchesNotifier extends StateNotifier<Branches> {
  BranchesNotifier() : super(const Branches());

  set stable(Branch? stable) {
    state = state.copyWith(
      stable: stable,
    );
  }

  set beta(Branch? beta) {
    state = state.copyWith(
      beta: beta,
    );
  }

  set master(Branch? master) {
    state = state.copyWith(
      master: master,
    );
  }
}

final StateNotifierProvider<BranchesNotifier, Branches> branchesProvider = StateNotifierProvider<BranchesNotifier, Branches>((_) {
  return BranchesNotifier();
});
