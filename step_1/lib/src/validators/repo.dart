library dartcov.validtors.repo;
import 'package:angel_validate/angel_validate.dart';

final Validator REPO = new Validator({
  'name': [isString, isNotEmpty],
  'desc': [isString, isNotEmpty]
});

final Validator CREATE_REPO = REPO.extend({})
  ..requiredFields.addAll(['name', 'desc']);