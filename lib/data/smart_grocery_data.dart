class SmartGroceryData {
  static Map<String, dynamic> getSmartGroceryData() {
    return {
      'oils': {
        'name': {'english': 'Oils', 'hindi': 'तेल', 'marathi': 'तेल'},
        'aliases': ['oil', 'tel', 'तेल', 'cooking oil'],
        'questions': {
          'brand': {
            'english': 'Which brand do you want?',
            'hindi': 'आप कौन सा ब्रांड चाहते हैं?',
            'marathi': 'तुम्हाला कोणता ब्रँड हवा?',
          },
          'quantity': {
            'english': 'How much quantity?',
            'hindi': 'कितनी मात्रा चाहिए?',
            'marathi': 'किती प्रमाण हवे?',
          },
        },
        'brands': {
          'gemini': {
            'name': 'Gemini',
            'types': {
              'sunflower': {
                'name': 'Sunflower Oil',
                'variants': {
                  '500ml': {'price': 95, 'mrp': 105},
                  '1l': {'price': 180, 'mrp': 195},
                  '2l': {'price': 350, 'mrp': 375},
                  '5l': {'price': 850, 'mrp': 895},
                },
              },
              'soybean': {
                'name': 'Soybean Oil',
                'variants': {
                  '1l': {'price': 185, 'mrp': 200},
                  '2l': {'price': 365, 'mrp': 385},
                },
              },
            },
          },
          'fortune': {
            'name': 'Fortune',
            'types': {
              'sunflower': {
                'name': 'Sunflower Oil',
                'variants': {
                  '500ml': {'price': 92, 'mrp': 102},
                  '1l': {'price': 175, 'mrp': 190},
                  '2l': {'price': 340, 'mrp': 365},
                },
              },
              'groundnut': {
                'name': 'Groundnut Oil',
                'variants': {
                  '1l': {'price': 185, 'mrp': 200},
                  '2l': {'price': 365, 'mrp': 385},
                },
              },
            },
          },
          'dhara': {
            'name': 'Dhara',
            'types': {
              'sunflower': {
                'name': 'Sunflower Oil',
                'variants': {
                  '500ml': {'price': 90, 'mrp': 100},
                  '1l': {'price': 170, 'mrp': 185},
                },
              },
            },
          },
          'saffola': {
            'name': 'Saffola',
            'types': {
              'sunflower': {
                'name': 'Sunflower Oil',
                'variants': {
                  '500ml': {'price': 105, 'mrp': 115},
                  '1l': {'price': 195, 'mrp': 210},
                },
              },
            },
          },
        },
      },

      'dairy': {
        'name': {
          'english': 'Dairy Products',
          'hindi': 'डेयरी उत्पाद',
          'marathi': 'दुग्ध पदार्थ',
        },
        'aliases': ['dairy', 'milk', 'दूध', 'paneer', 'दही'],
        'questions': {
          'brand': {
            'english': 'Which brand do you prefer?',
            'hindi': 'आप कौन सा ब्रांड पसंद करते हैं?',
            'marathi': 'तुम्हाला कोणता ब्रँड आवडतो?',
          },
          'type': {
            'english': 'Which type do you want?',
            'hindi': 'आप कौन सा प्रकार चाहते हैं?',
            'marathi': 'तुम्हाला कोणता प्रकार हवा?',
          },
          'quantity': {
            'english': 'How much quantity?',
            'hindi': 'कितनी मात्रा?',
            'marathi': 'किती प्रमाण?',
          },
        },
        'brands': {
          'amul': {
            'name': 'Amul',
            'types': {
              'milk': {
                'name': 'Milk',
                'variants': {
                  'full_cream_500ml': {
                    'name': 'Full Cream Milk 500ml',
                    'price': 32,
                    'mrp': 35,
                  },
                  'full_cream_1l': {
                    'name': 'Full Cream Milk 1L',
                    'price': 62,
                    'mrp': 68,
                  },
                  'toned_500ml': {
                    'name': 'Toned Milk 500ml',
                    'price': 28,
                    'mrp': 32,
                  },
                  'toned_1l': {'name': 'Toned Milk 1L', 'price': 54, 'mrp': 58},
                },
              },
              'paneer': {
                'name': 'Paneer',
                'variants': {
                  '100g': {'price': 45, 'mrp': 50},
                  '200g': {'price': 85, 'mrp': 92},
                  '500g': {'price': 195, 'mrp': 210},
                },
              },
              'butter': {
                'name': 'Butter',
                'variants': {
                  '100g': {'price': 58, 'mrp': 62},
                  '500g': {'price': 285, 'mrp': 295},
                },
              },
              'curd': {
                'name': 'Curd',
                'variants': {
                  '200g': {'price': 28, 'mrp': 32},
                  '400g': {'price': 52, 'mrp': 58},
                },
              },
            },
          },
          'mother_dairy': {
            'name': 'Mother Dairy',
            'types': {
              'milk': {
                'name': 'Milk',
                'variants': {
                  'full_cream_500ml': {
                    'name': 'Full Cream Milk 500ml',
                    'price': 34,
                    'mrp': 38,
                  },
                  'full_cream_1l': {
                    'name': 'Full Cream Milk 1L',
                    'price': 66,
                    'mrp': 72,
                  },
                },
              },
              'paneer': {
                'name': 'Paneer',
                'variants': {
                  '200g': {'price': 88, 'mrp': 95},
                },
              },
            },
          },
        },
      },

      'rice': {
        'name': {
          'english': 'Rice & Grains',
          'hindi': 'चावल और अनाज',
          'marathi': 'तांदूळ आणि धान्य',
        },
        'aliases': ['rice', 'chawal', 'तांदूळ', 'चावल', 'atta', 'आटा'],
        'questions': {
          'brand': {
            'english': 'Which brand do you want?',
            'hindi': 'आप कौन सा ब्रांड चाहते हैं?',
            'marathi': 'तुम्हाला कोणता ब्रँड हवा?',
          },
          'type': {
            'english': 'Which type of rice?',
            'hindi': 'कौन सा चावल चाहिए?',
            'marathi': 'कोणता तांदूळ हवा?',
          },
          'quantity': {
            'english': 'How much quantity?',
            'hindi': 'कितनी मात्रा?',
            'marathi': 'किती प्रमाण?',
          },
        },
        'brands': {
          'india_gate': {
            'name': 'India Gate',
            'types': {
              'basmati': {
                'name': 'Basmati Rice',
                'variants': {
                  '1kg': {'price': 125, 'mrp': 135},
                  '5kg': {'price': 450, 'mrp': 485},
                  '10kg': {'price': 885, 'mrp': 920},
                },
              },
            },
          },
          'daawat': {
            'name': 'Daawat',
            'types': {
              'basmati': {
                'name': 'Basmati Rice',
                'variants': {
                  '1kg': {'price': 135, 'mrp': 145},
                  '5kg': {'price': 475, 'mrp': 510},
                },
              },
            },
          },
          'aashirvaad': {
            'name': 'Aashirvaad',
            'types': {
              'atta': {
                'name': 'Wheat Flour',
                'variants': {
                  '1kg': {'price': 62, 'mrp': 68},
                  '5kg': {'price': 285, 'mrp': 305},
                  '10kg': {'price': 545, 'mrp': 580},
                },
              },
            },
          },
        },
      },

      'spices': {
        'name': {
          'english': 'Spices & Masalas',
          'hindi': 'मसाले',
          'marathi': 'मसाले',
        },
        'aliases': ['spices', 'masala', 'मसाला', 'हल्दी', 'turmeric', 'mirchi'],
        'questions': {
          'brand': {
            'english': 'Which spice brand?',
            'hindi': 'कौन सा मसाला ब्रांड?',
            'marathi': 'कोणता मसाला ब्रँड?',
          },
          'type': {
            'english': 'Which spice do you need?',
            'hindi': 'कौन सा मसाला चाहिए?',
            'marathi': 'कोणता मसाला हवा?',
          },
          'quantity': {
            'english': 'Which size?',
            'hindi': 'कौन सा साइज़?',
            'marathi': 'कोणता साइज़?',
          },
        },
        'brands': {
          'mdh': {
            'name': 'MDH',
            'types': {
              'turmeric': {
                'name': 'Turmeric Powder',
                'variants': {
                  '50g': {'price': 25, 'mrp': 28},
                  '100g': {'price': 45, 'mrp': 50},
                  '200g': {'price': 85, 'mrp': 92},
                },
              },
              'red_chili': {
                'name': 'Red Chili Powder',
                'variants': {
                  '100g': {'price': 48, 'mrp': 52},
                  '200g': {'price': 92, 'mrp': 98},
                },
              },
              'garam_masala': {
                'name': 'Garam Masala',
                'variants': {
                  '50g': {'price': 45, 'mrp': 48},
                  '100g': {'price': 85, 'mrp': 92},
                },
              },
            },
          },
          'everest': {
            'name': 'Everest',
            'types': {
              'turmeric': {
                'name': 'Turmeric Powder',
                'variants': {
                  '100g': {'price': 42, 'mrp': 45},
                  '200g': {'price': 78, 'mrp': 85},
                },
              },
              'red_chili': {
                'name': 'Red Chili Powder',
                'variants': {
                  '100g': {'price': 42, 'mrp': 48},
                },
              },
            },
          },
        },
      },

      'pulses': {
        'name': {
          'english': 'Pulses & Lentils',
          'hindi': 'दालें',
          'marathi': 'डाळी',
        },
        'aliases': ['dal', 'pulse', 'lentils', 'दाल', 'डाळ'],
        'questions': {
          'brand': {
            'english': 'Which dal brand?',
            'hindi': 'कौन सा दाल ब्रांड?',
            'marathi': 'कोणता डाळ ब्रँड?',
          },
          'type': {
            'english': 'Which dal do you want?',
            'hindi': 'कौन सी दाल चाहिए?',
            'marathi': 'कोणती डाळ हवी?',
          },
          'quantity': {
            'english': 'How much quantity?',
            'hindi': 'कितनी मात्रा?',
            'marathi': 'किती प्रमाण?',
          },
        },
        'brands': {
          'tata_sampann': {
            'name': 'Tata Sampann',
            'types': {
              'toor_dal': {
                'name': 'Toor Dal',
                'variants': {
                  '500g': {'price': 85, 'mrp': 92},
                  '1kg': {'price': 165, 'mrp': 175},
                },
              },
              'moong_dal': {
                'name': 'Moong Dal',
                'variants': {
                  '1kg': {'price': 125, 'mrp': 135},
                },
              },
            },
          },
          'fortune': {
            'name': 'Fortune',
            'types': {
              'toor_dal': {
                'name': 'Toor Dal',
                'variants': {
                  '1kg': {'price': 155, 'mrp': 165},
                },
              },
              'chana_dal': {
                'name': 'Chana Dal',
                'variants': {
                  '1kg': {'price': 115, 'mrp': 125},
                },
              },
            },
          },
        },
      },

      'snacks': {
        'name': {
          'english': 'Snacks & Biscuits',
          'hindi': 'नमकीन और बिस्कुट',
          'marathi': 'नमकीन आणि बिस्कीट',
        },
        'aliases': ['snacks', 'biscuits', 'namkeen', 'नमकीन', 'बिस्कुट'],
        'questions': {
          'brand': {
            'english': 'Which brand?',
            'hindi': 'कौन सा ब्रांड?',
            'marathi': 'कोणता ब्रँड?',
          },
          'type': {
            'english': 'What type of snack?',
            'hindi': 'कौन सा स्नैक?',
            'marathi': 'कोणता स्नॅक?',
          },
          'quantity': {
            'english': 'Which size?',
            'hindi': 'कौन सा साइज़?',
            'marathi': 'कोणता साइज़?',
          },
        },
        'brands': {
          'parle': {
            'name': 'Parle',
            'types': {
              'parle_g': {
                'name': 'Parle-G Biscuits',
                'variants': {
                  '75g': {'price': 12, 'mrp': 15},
                  '150g': {'price': 22, 'mrp': 25},
                  '300g': {'price': 45, 'mrp': 50},
                },
              },
            },
          },
          'britannia': {
            'name': 'Britannia',
            'types': {
              'marie': {
                'name': 'Marie Gold',
                'variants': {
                  '150g': {'price': 25, 'mrp': 28},
                },
              },
              'good_day': {
                'name': 'Good Day Cookies',
                'variants': {
                  '150g': {'price': 35, 'mrp': 38},
                },
              },
            },
          },
          'haldirams': {
            'name': 'Haldiram\'s',
            'types': {
              'bhujia': {
                'name': 'Bhujia',
                'variants': {
                  '200g': {'price': 58, 'mrp': 65},
                  '400g': {'price': 115, 'mrp': 125},
                },
              },
              'mixture': {
                'name': 'Mixture',
                'variants': {
                  '200g': {'price': 65, 'mrp': 72},
                },
              },
            },
          },
        },
      },

      'beverages': {
        'name': {
          'english': 'Beverages',
          'hindi': 'पेय पदार्थ',
          'marathi': 'पेय पदार्थ',
        },
        'aliases': ['drinks', 'beverages', 'tea', 'coffee', 'चाय', 'कॉफी'],
        'questions': {
          'brand': {
            'english': 'Which brand?',
            'hindi': 'कौन सा ब्रांड?',
            'marathi': 'कोणता ब्रँड?',
          },
          'type': {
            'english': 'What type of drink?',
            'hindi': 'कौन सा पेय?',
            'marathi': 'कोणते पेय?',
          },
          'quantity': {
            'english': 'Which size?',
            'hindi': 'कौन सा साइज़?',
            'marathi': 'कोणता साइज़?',
          },
        },
        'brands': {
          'tata_tea': {
            'name': 'Tata Tea',
            'types': {
              'gold': {
                'name': 'Tata Tea Gold',
                'variants': {
                  '250g': {'price': 148, 'mrp': 155},
                  '500g': {'price': 285, 'mrp': 295},
                },
              },
            },
          },
          'nescafe': {
            'name': 'Nescafe',
            'types': {
              'classic': {
                'name': 'Classic Coffee',
                'variants': {
                  '50g': {'price': 145, 'mrp': 155},
                  '100g': {'price': 285, 'mrp': 295},
                },
              },
            },
          },
        },
      },

      'personal_care': {
        'name': {
          'english': 'Personal Care',
          'hindi': 'व्यक्तिगत देखभाल',
          'marathi': 'वैयक्तिक काळजी',
        },
        'aliases': ['soap', 'shampoo', 'toothpaste', 'साबुन', 'शैम्पू'],
        'questions': {
          'brand': {
            'english': 'Which brand?',
            'hindi': 'कौन सा ब्रांड?',
            'marathi': 'कोणता ब्रँड?',
          },
          'type': {
            'english': 'What type of personal care item?',
            'hindi': 'कौन सा व्यक्तिगत देखभाल का सामान?',
            'marathi': 'कोणता वैयक्तिक काळजीचा सामान?',
          },
          'quantity': {
            'english': 'Which size?',
            'hindi': 'कौन सा साइज़?',
            'marathi': 'कोणता साइज़?',
          },
        },
        'brands': {
          'dove': {
            'name': 'Dove',
            'types': {
              'beauty_bar': {
                'name': 'Beauty Bar Soap',
                'variants': {
                  '100g': {'price': 45, 'mrp': 50},
                },
              },
            },
          },
          'pantene': {
            'name': 'Pantene',
            'types': {
              'shampoo': {
                'name': 'Hair Shampoo',
                'variants': {
                  '340ml': {'price': 285, 'mrp': 295},
                },
              },
            },
          },
          'colgate': {
            'name': 'Colgate',
            'types': {
              'toothpaste': {
                'name': 'Toothpaste',
                'variants': {
                  '100g': {'price': 85, 'mrp': 92},
                },
              },
            },
          },
        },
      },

      'household': {
        'name': {
          'english': 'Household Items',
          'hindi': 'घरेलू सामान',
          'marathi': 'घरगुती वस्तू',
        },
        'aliases': ['detergent', 'cleaner', 'household', 'घरेलू'],
        'questions': {
          'brand': {
            'english': 'Which brand?',
            'hindi': 'कौन सा ब्रांड?',
            'marathi': 'कोणता ब्रँड?',
          },
          'type': {
            'english': 'What type of household item?',
            'hindi': 'कौन सा घरेलू सामान?',
            'marathi': 'कोणता घरगुती सामान?',
          },
          'quantity': {
            'english': 'Which size?',
            'hindi': 'कौन सा साइज़?',
            'marathi': 'कोणता साइज़?',
          },
        },
        'brands': {
          'surf_excel': {
            'name': 'Surf Excel',
            'types': {
              'detergent': {
                'name': 'Washing Powder',
                'variants': {
                  '500g': {'price': 85, 'mrp': 92},
                  '1kg': {'price': 165, 'mrp': 175},
                  '2kg': {'price': 315, 'mrp': 335},
                },
              },
            },
          },
          'vim': {
            'name': 'Vim',
            'types': {
              'dishwash': {
                'name': 'Dishwash Liquid',
                'variants': {
                  '500ml': {'price': 85, 'mrp': 92},
                  '1l': {'price': 165, 'mrp': 175},
                },
              },
            },
          },
        },
      },
    };
  }
}
