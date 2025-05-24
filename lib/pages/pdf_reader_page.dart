import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:readz/models/pdf_items.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class PdfEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPdfList extends PdfEvent {}

class SelectPdf extends PdfEvent {
  final PdfItem pdfItem;

  SelectPdf(this.pdfItem);

  @override
  List<Object?> get props => [pdfItem];
}

class ClearSelectedPdf extends PdfEvent {}

// States
abstract class PdfState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PdfInitial extends PdfState {}

class PdfListLoading extends PdfState {}

class PdfListLoaded extends PdfState {
  final List<PdfItem> pdfList;

  PdfListLoaded(this.pdfList);

  @override
  List<Object?> get props => [pdfList];
}

class PdfListError extends PdfState {
  final String message;

  PdfListError(this.message);

  @override
  List<Object?> get props => [message];
}

class PdfSelected extends PdfState {
  final List<PdfItem> pdfList;
  final PdfItem selectedPdf;

  PdfSelected({required this.pdfList, required this.selectedPdf});

  @override
  List<Object?> get props => [pdfList, selectedPdf];
}

// Bloc
class PdfBloc extends Bloc<PdfEvent, PdfState> {
  final Dio _dio = Dio();

  // Replace with your GitHub repository details
  static const String githubUser = 'Ibrahim-Lokman';
  static const String githubRepo = 'readz';
  static const String pdfFolder = 'pdfs'; // folder containing PDFs

  PdfBloc() : super(PdfInitial()) {
    on<LoadPdfList>(_onLoadPdfList);
    on<SelectPdf>(_onSelectPdf);
    on<ClearSelectedPdf>(_onClearSelectedPdf);
  }

  Future<void> _onLoadPdfList(LoadPdfList event, Emitter<PdfState> emit) async {
    emit(PdfListLoading());

    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$githubUser/$githubRepo/contents/$pdfFolder',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final List<PdfItem> pdfList = data
            .where((item) =>
                item['name'].toString().toLowerCase().endsWith('.pdf'))
            .map((item) => PdfItem.fromJson(item))
            .toList();

        emit(PdfListLoaded(pdfList));
      } else {
        emit(PdfListError('Failed to load PDF list'));
      }
    } catch (e) {
      emit(PdfListError('Error: ${e.toString()}'));
    }
  }

  void _onSelectPdf(SelectPdf event, Emitter<PdfState> emit) {
    final currentState = state;
    if (currentState is PdfListLoaded) {
      emit(PdfSelected(
        pdfList: currentState.pdfList,
        selectedPdf: event.pdfItem,
      ));
    }
  }

  void _onClearSelectedPdf(ClearSelectedPdf event, Emitter<PdfState> emit) {
    final currentState = state;
    if (currentState is PdfSelected) {
      emit(PdfListLoaded(currentState.pdfList));
    }
  }
}

// Main Page Widget
class PdfReaderPage extends StatelessWidget {
  const PdfReaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PdfBloc()..add(LoadPdfList()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PDF Reader'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: BlocBuilder<PdfBloc, PdfState>(
          builder: (context, state) {
            if (state is PdfInitial || state is PdfListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PdfListError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading PDFs',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<PdfBloc>().add(LoadPdfList()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is PdfSelected) {
              return PdfViewerWidget(
                pdfItem: state.selectedPdf,
                onBack: () => context.read<PdfBloc>().add(ClearSelectedPdf()),
              );
            }

            if (state is PdfListLoaded) {
              return PdfListWidget(pdfList: state.pdfList);
            }

            return const Center(child: Text('Unknown state'));
          },
        ),
      ),
    );
  }
}

// PDF List Widget
class PdfListWidget extends StatelessWidget {
  final List<PdfItem> pdfList;

  const PdfListWidget({super.key, required this.pdfList});

  @override
  Widget build(BuildContext context) {
    if (pdfList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No PDFs found'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available PDFs (${pdfList.length})',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: pdfList.length,
              itemBuilder: (context, index) {
                final pdf = pdfList[index];
                return Card(
                  elevation: 4,
                  child: InkWell(
                    onTap: () => context.read<PdfBloc>().add(SelectPdf(pdf)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pdf.name.replaceAll('.pdf', ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// PDF Viewer Widget
class PdfViewerWidget extends StatelessWidget {
  final PdfItem pdfItem;
  final VoidCallback onBack;

  const PdfViewerWidget({
    super.key,
    required this.pdfItem,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pdfItem.name.replaceAll('.pdf', ''),
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Open PDF in new tab
                  // You can implement this based on your needs
                },
                icon: const Icon(Icons.open_in_new),
              ),
            ],
          ),
        ),
        Expanded(
          child: SfPdfViewer.network(
            pdfItem.downloadUrl,
            onDocumentLoadFailed: (details) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load PDF: ${details.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
