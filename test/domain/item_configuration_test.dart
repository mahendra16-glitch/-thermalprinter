import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';

const size = OptionGroup(
  id: 'size',
  name: 'Size',
  kind: OptionGroupKind.variant,
  minSelect: 1,
  maxSelect: 1,
  choices: [
    OptionChoice(id: 'half', groupId: 'size', name: 'Half'),
    OptionChoice(
      id: 'full',
      groupId: 'size',
      name: 'Full',
      priceDelta: Money(8000),
    ),
    OptionChoice(id: 'xl', groupId: 'size', name: 'XL', isActive: false),
  ],
);

const extras = OptionGroup(
  id: 'extras',
  name: 'Extras',
  kind: OptionGroupKind.addon,
  minSelect: 0,
  maxSelect: 2,
  choices: [
    OptionChoice(
      id: 'cheese',
      groupId: 'extras',
      name: 'Extra cheese',
      priceDelta: Money(3000),
    ),
    OptionChoice(id: 'onion', groupId: 'extras', name: 'No onion'),
    OptionChoice(
      id: 'dip',
      groupId: 'extras',
      name: 'Mint dip',
      priceDelta: Money(1500),
    ),
  ],
);

const retired = OptionGroup(
  id: 'retired',
  name: 'Old group',
  kind: OptionGroupKind.addon,
  minSelect: 1,
  isActive: false,
);

const item = MenuItem(
  id: 'tikka',
  categoryId: 'starters',
  name: 'Paneer Tikka',
  basePrice: Money(18000),
  stationId: 'kitchen',
  optionGroupIds: ['size', 'extras', 'retired'],
);

final groups = {
  for (final g in [size, extras, retired]) g.id: g,
};

void main() {
  group('validateSelection', () {
    final offered = offeredGroups(item, groups);

    test('inactive groups are not offered', () {
      expect(offered.map((g) => g.id), ['size', 'extras']);
    });

    test('required single-select group must have exactly one', () {
      expect(
        validateSelection(offered, {}).single.message,
        'Size: choose one.',
      );
      expect(
        validateSelection(offered, {
          'size': {'half', 'full'},
        }).single.message,
        'Size: choose only one.',
      );
      expect(
        validateSelection(offered, {
          'size': {'half'},
        }),
        isEmpty,
      );
    });

    test('multi-select maximum is enforced', () {
      final errors = validateSelection(offered, {
        'size': {'half'},
        'extras': {'cheese', 'onion', 'dip'},
      });
      expect(errors.single.message, 'Extras: choose at most 2.');
    });

    test('inactive or unknown choices are rejected', () {
      expect(
        validateSelection(offered, {
          'size': {'xl'},
        }).single.message,
        contains('unavailable'),
      );
      expect(
        validateSelection(offered, {
          'size': {'half'},
          'nope': {'x'},
        }).single.message,
        contains('not offered'),
      );
    });

    test('minimum greater than one is enforced', () {
      const pickTwo = OptionGroup(
        id: 'p',
        name: 'Sides',
        kind: OptionGroupKind.addon,
        minSelect: 2,
        maxSelect: 3,
        choices: [
          OptionChoice(id: 'a', groupId: 'p', name: 'A'),
          OptionChoice(id: 'b', groupId: 'p', name: 'B'),
        ],
      );
      expect(
        validateSelection(
          [pickTwo],
          {
            'p': {'a'},
          },
        ).single.message,
        'Sides: choose at least 2.',
      );
    });
  });

  group('configureItem', () {
    const gst5 = TaxProfile(
      id: 'gst5',
      name: 'GST 5%',
      rateBp: 500,
      isInclusive: true,
      splitMode: TaxSplitMode.cgstSgst,
    );

    test('price = base + chosen options; snapshot copies tax', () {
      final c = configureItem(
        item: item,
        groups: groups,
        selected: {
          'size': {'full'},
          'extras': {'dip', 'cheese'},
        },
        tax: gst5,
      );
      expect(c.unitPrice, const Money(18000 + 8000 + 3000 + 1500));
      expect(c.variantText, 'Full');
      // Group display order, not tap order.
      expect(c.addons.map((a) => a.name), ['Extra cheese', 'Mint dip']);
      expect(c.taxRateBp, 500);
      expect(c.taxInclusive, isTrue);
      expect(c.taxSplitMode, TaxSplitMode.cgstSgst);
      expect(c.stationId, 'kitchen');
      expect(c.itemName, 'Paneer Tikka');
    });

    test('untaxed item has a zero rate', () {
      final c = configureItem(
        item: item,
        groups: groups,
        selected: {
          'size': {'half'},
        },
      );
      expect(c.taxRateBp, 0);
      expect(c.unitPrice, const Money(18000));
    });

    test('invalid selection throws and builds nothing', () {
      expect(
        () => configureItem(item: item, groups: groups, selected: {}),
        throwsA(isA<InvalidSelectionException>()),
      );
    });
  });

  group('group rules', () {
    test('rule labels', () {
      expect(size.ruleLabel, 'Pick 1');
      expect(extras.ruleLabel, 'Optional, up to 2');
      expect(
        const OptionGroup(
          id: 'x',
          name: 'x',
          kind: OptionGroupKind.addon,
          minSelect: 1,
          maxSelect: 3,
        ).ruleLabel,
        'Pick 1 to 3',
      );
    });

    test('unsatisfiable minimum is reported', () {
      expect(retired.configurationProblems, isNotEmpty);
      expect(size.configurationProblems, isEmpty);
    });
  });

  group('percent parsing', () {
    test('valid', () {
      expect(parsePercentToBp('5'), 500);
      expect(parsePercentToBp('2.5'), 250);
      expect(parsePercentToBp('18.25 %'), 1825);
      expect(parsePercentToBp('0'), 0);
      expect(parsePercentToBp('100'), 10000);
    });

    test('invalid', () {
      for (final s in ['', '-5', '101', '5.123', 'abc']) {
        expect(parsePercentToBp(s), isNull, reason: s);
      }
    });

    test('format', () {
      expect(formatBp(500), '5%');
      expect(formatBp(250), '2.5%');
      expect(formatBp(1825), '18.25%');
      expect(formatBp(1205), '12.05%');
    });
  });
}
