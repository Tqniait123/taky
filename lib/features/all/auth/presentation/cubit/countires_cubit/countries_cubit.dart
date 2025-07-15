import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taqy/features/all/auth/data/models/country.dart';
import 'package:taqy/features/all/auth/data/repositories/auth_repo.dart';

part 'countries_state.dart';

class CountriesCubit extends Cubit<CountriesState> {
  CountriesCubit(this.authRepo) : super(CountriesInitial());
  final AuthRepo authRepo;

  static CountriesCubit get(context) => BlocProvider.of(context);

  Future<void> getCountries() async {
    emit(CountriesLoading());

    final result = await authRepo.getCountries();

    result.fold((countries) => emit(CountriesLoaded(countries)), (error) => emit(CountriesError(error.message)));
  }
}
