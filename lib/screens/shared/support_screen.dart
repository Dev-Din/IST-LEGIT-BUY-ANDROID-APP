import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _FAQItem(
              question: 'How do I place an order?',
              answer:
                  'Browse products, add items to your cart, and proceed to checkout. Enter your M-Pesa phone number to complete the payment.',
            ),
            _FAQItem(
              question: 'What payment methods do you accept?',
              answer: 'We currently accept M-Pesa payments only.',
            ),
            _FAQItem(
              question: 'How long does delivery take?',
              answer:
                  'Delivery times vary depending on your location. You will receive a notification once your order is shipped.',
            ),
            _FAQItem(
              question: 'Can I cancel my order?',
              answer:
                  'You can cancel your order within 24 hours of placing it. Contact support for assistance.',
            ),
            _FAQItem(
              question: 'How do I track my order?',
              answer:
                  'You can view your order status in the Order History section of the app.',
            ),
            const SizedBox(height: 32),
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: const Text('support@legitbuy.com'),
                      onTap: () {
                        // Open email client
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Phone'),
                      subtitle: const Text('+254 700 000 000'),
                      onTap: () {
                        // Open phone dialer
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(widget.question),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(widget.answer),
          ),
        ],
      ),
    );
  }
}
