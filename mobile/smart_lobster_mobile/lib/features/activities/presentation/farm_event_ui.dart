import 'package:flutter/material.dart';

import '../models/farm_event_type.dart';

extension FarmEventTypeUi on FarmEventType {
  IconData get icon => switch (this) {
    FarmEventType.feeding => Icons.restaurant_outlined,
    FarmEventType.waterChange => Icons.autorenew_rounded,
    FarmEventType.waterAddition => Icons.water_drop_outlined,
    FarmEventType.molting => Icons.visibility_outlined,
    FarmEventType.mating => Icons.favorite_border_rounded,
    FarmEventType.maintenance => Icons.build_outlined,
  };
}
