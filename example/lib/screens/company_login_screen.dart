import 'package:flutter/material.dart';
import '../data/company_data.dart';
import '../theme/atomic_theme.dart';

class CompanyLoginScreen extends StatelessWidget {
  final List<CompanySuggestion> companies;
  final void Function(String id, String name) onSelectCompany;

  const CompanyLoginScreen({
    super.key,
    required this.companies,
    required this.onSelectCompany,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Company'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        itemCount: companies.length,
        itemBuilder: (context, index) {
          final company = companies[index];
          return _CompanyRow(
            company: company,
            onTap: () {
              onSelectCompany(company.id, company.name);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}

class _CompanyRow extends StatelessWidget {
  final CompanySuggestion company;
  final VoidCallback onTap;

  const _CompanyRow({required this.company, required this.onTap});

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 3) {
      cleaned = cleaned.split('').map((c) => '$c$c').join();
    }
    if (cleaned.length != 6) return null;
    try {
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsedColor = _parseHex(company.brandColor);
    final bgColor = parsedColor ?? atomicSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: company.logoUrl != null
                  ? Image.network(
                      company.logoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: atomicOnBackground,
                    ),
                  ),
                  if (company.fullName != null)
                    Text(
                      company.fullName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: atomicOnSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
