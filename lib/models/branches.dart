import 'package:flutter/widgets.dart' show immutable;
import 'branch.dart';

/// A container for all three Branches.
@immutable
class Branches {
  const Branches({
    final this.stable,
    final this.beta,
    final this.master,
  });

  final Branch? stable;
  final Branch? beta;
  final Branch? master;

  Branches copyWith({ Branch? stable, Branch? beta, Branch? master}) {
    return Branches(
      stable: stable ?? this.stable,
      beta: beta ?? this.beta,
      master: master ?? this.master,
    );
  }

  @override
  String toString() {
    return 'Branches stable: $stable, beta: $beta, master: $master';
  }
}
