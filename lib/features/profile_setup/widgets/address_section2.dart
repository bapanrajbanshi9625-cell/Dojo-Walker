import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AddressSection2 extends StatefulWidget {
  const AddressSection2({
    super.key,
    required this.villageController,
    required this.cityController,
    required this.districtController,
    required this.stateController,
    required this.pinController,
    required this.fullAddress,
    required this.enabled,
  });

  final TextEditingController villageController;
  final TextEditingController cityController;
  final TextEditingController districtController;
  final TextEditingController stateController;
  final TextEditingController pinController;

  final String fullAddress;
  final bool enabled;

  @override
  State<AddressSection2> createState() =>
      _AddressSection2State();
}

class _AddressSection2State
    extends State<AddressSection2> {
  // ==========================================================
  // INDIAN STATES + DISTRICTS
  // ==========================================================

  static const Map<String, List<String>> stateDistricts =
      <String, List<String>>{
    'Andhra Pradesh': <String>[
      'Alluri Sitharama Raju',
      'Anakapalli',
      'Anantapur',
      'Annamayya',
      'Bapatla',
      'Chittoor',
      'Dr. B.R. Ambedkar Konaseema',
      'East Godavari',
      'Eluru',
      'Guntur',
      'Kakinada',
      'Krishna',
      'Kurnool',
      'Nandyal',
      'NTR',
      'Palnadu',
      'Parvathipuram Manyam',
      'Prakasam',
      'Srikakulam',
      'Sri Sathya Sai',
      'Tirupati',
      'Visakhapatnam',
      'Vizianagaram',
      'West Godavari',
      'YSR Kadapa',
    ],

    'Arunachal Pradesh': <String>[
      'Anjaw',
      'Bichom',
      'Changlang',
      'Dibang Valley',
      'East Kameng',
      'East Siang',
      'Itanagar Capital Complex',
      'Kamle',
      'Keyi Panyor',
      'Kra Daadi',
      'Kurung Kumey',
      'Lepa Rada',
      'Lohit',
      'Longding',
      'Lower Dibang Valley',
      'Lower Siang',
      'Lower Subansiri',
      'Namsai',
      'Pakke Kessang',
      'Papum Pare',
      'Shi Yomi',
      'Siang',
      'Tawang',
      'Tirap',
      'Upper Siang',
      'Upper Subansiri',
      'West Kameng',
      'West Siang',
    ],

    'Assam': <String>[
      'Baksa',
      'Bajali',
      'Barpeta',
      'Biswanath',
      'Bongaigaon',
      'Cachar',
      'Charaideo',
      'Chirang',
      'Darrang',
      'Dhemaji',
      'Dhubri',
      'Dibrugarh',
      'Dima Hasao',
      'Goalpara',
      'Golaghat',
      'Hailakandi',
      'Hojai',
      'Jorhat',
      'Kamrup',
      'Kamrup Metropolitan',
      'Karbi Anglong',
      'Karimganj',
      'Kokrajhar',
      'Lakhimpur',
      'Majuli',
      'Morigaon',
      'Nagaon',
      'Nalbari',
      'Sivasagar',
      'Sonitpur',
      'South Salmara-Mankachar',
      'Tamulpur',
      'Tinsukia',
      'Udalguri',
      'West Karbi Anglong',
    ],

    'Bihar': <String>[
      'Araria',
      'Arwal',
      'Aurangabad',
      'Banka',
      'Begusarai',
      'Bhagalpur',
      'Bhojpur',
      'Buxar',
      'Darbhanga',
      'East Champaran',
      'Gaya',
      'Gopalganj',
      'Jamui',
      'Jehanabad',
      'Kaimur',
      'Katihar',
      'Khagaria',
      'Kishanganj',
      'Lakhisarai',
      'Madhepura',
      'Madhubani',
      'Munger',
      'Muzaffarpur',
      'Nalanda',
      'Nawada',
      'Patna',
      'Purnia',
      'Rohtas',
      'Saharsa',
      'Samastipur',
      'Saran',
      'Sheikhpura',
      'Sheohar',
      'Sitamarhi',
      'Siwan',
      'Supaul',
      'Vaishali',
      'West Champaran',
    ],

    'Chhattisgarh': <String>[
      'Balod',
      'Baloda Bazar',
      'Balrampur',
      'Bastar',
      'Bemetara',
      'Bijapur',
      'Bilaspur',
      'Dantewada',
      'Dhamtari',
      'Durg',
      'Gariaband',
      'Gaurela-Pendra-Marwahi',
      'Janjgir-Champa',
      'Jashpur',
      'Kabirdham',
      'Kanker',
      'Khairagarh-Chhuikhadan-Gandai',
      'Kondagaon',
      'Korba',
      'Korea',
      'Mahasamund',
      'Manendragarh-Chirmiri-Bharatpur',
      'Mohla-Manpur-Ambagarh Chowki',
      'Mungeli',
      'Narayanpur',
      'Raigarh',
      'Raipur',
      'Rajnandgaon',
      'Sakti',
      'Sarangarh-Bilaigarh',
      'Sukma',
      'Surajpur',
      'Surguja',
    ],

    'Goa': <String>[
      'North Goa',
      'South Goa',
    ],

    'Gujarat': <String>[
      'Ahmedabad',
      'Amreli',
      'Anand',
      'Aravalli',
      'Banaskantha',
      'Bharuch',
      'Bhavnagar',
      'Botad',
      'Chhota Udaipur',
      'Dahod',
      'Dang',
      'Devbhoomi Dwarka',
      'Gandhinagar',
      'Gir Somnath',
      'Jamnagar',
      'Junagadh',
      'Kheda',
      'Kutch',
      'Mahisagar',
      'Mehsana',
      'Morbi',
      'Narmada',
      'Navsari',
      'Panchmahal',
      'Patan',
      'Porbandar',
      'Rajkot',
      'Sabarkantha',
      'Surat',
      'Surendranagar',
      'Tapi',
      'Vadodara',
      'Valsad',
    ],

    'Haryana': <String>[
      'Ambala',
      'Bhiwani',
      'Charkhi Dadri',
      'Faridabad',
      'Fatehabad',
      'Gurugram',
      'Hisar',
      'Jhajjar',
      'Jind',
      'Kaithal',
      'Karnal',
      'Kurukshetra',
      'Mahendragarh',
      'Nuh',
      'Palwal',
      'Panchkula',
      'Panipat',
      'Rewari',
      'Rohtak',
      'Sirsa',
      'Sonipat',
      'Yamunanagar',
    ],

    'Himachal Pradesh': <String>[
      'Bilaspur',
      'Chamba',
      'Hamirpur',
      'Kangra',
      'Kinnaur',
      'Kullu',
      'Lahaul and Spiti',
      'Mandi',
      'Shimla',
      'Sirmaur',
      'Solan',
      'Una',
    ],

    'Jharkhand': <String>[
      'Bokaro',
      'Chatra',
      'Deoghar',
      'Dhanbad',
      'Dumka',
      'East Singhbhum',
      'Garhwa',
      'Giridih',
      'Godda',
      'Gumla',
      'Hazaribagh',
      'Jamtara',
      'Khunti',
      'Koderma',
      'Latehar',
      'Lohardaga',
      'Pakur',
      'Palamu',
      'Ramgarh',
      'Ranchi',
      'Sahebganj',
      'Seraikela Kharsawan',
      'Simdega',
      'West Singhbhum',
    ],

    'Karnataka': <String>[
      'Bagalkot',
      'Ballari',
      'Belagavi',
      'Bengaluru Rural',
      'Bengaluru Urban',
      'Bidar',
      'Chamarajanagar',
      'Chikkaballapur',
      'Chikkamagaluru',
      'Chitradurga',
      'Dakshina Kannada',
      'Davanagere',
      'Dharwad',
      'Gadag',
      'Hassan',
      'Haveri',
      'Kalaburagi',
      'Kodagu',
      'Kolar',
      'Koppal',
      'Mandya',
      'Mysuru',
      'Raichur',
      'Ramanagara',
      'Shivamogga',
      'Tumakuru',
      'Udupi',
      'Uttara Kannada',
      'Vijayanagara',
      'Vijayapura',
      'Yadgir',
    ],

    'Kerala': <String>[
      'Alappuzha',
      'Ernakulam',
      'Idukki',
      'Kannur',
      'Kasaragod',
      'Kollam',
      'Kottayam',
      'Kozhikode',
      'Malappuram',
      'Palakkad',
      'Pathanamthitta',
      'Thiruvananthapuram',
      'Thrissur',
      'Wayanad',
    ],

    'Madhya Pradesh': <String>[
      'Agar Malwa',
      'Alirajpur',
      'Anuppur',
      'Ashoknagar',
      'Balaghat',
      'Barwani',
      'Betul',
      'Bhind',
      'Bhopal',
      'Burhanpur',
      'Chhatarpur',
      'Chhindwara',
      'Damoh',
      'Datia',
      'Dewas',
      'Dhar',
      'Dindori',
      'Guna',
      'Gwalior',
      'Harda',
      'Indore',
      'Jabalpur',
      'Jhabua',
      'Katni',
      'Khandwa',
      'Khargone',
      'Maihar',
      'Mandla',
      'Mandsaur',
      'Mauganj',
      'Morena',
      'Narmadapuram',
      'Narsinghpur',
      'Neemuch',
      'Niwari',
      'Panna',
      'Raisen',
      'Rajgarh',
      'Ratlam',
      'Rewa',
      'Sagar',
      'Satna',
      'Sehore',
      'Seoni',
      'Shahdol',
      'Shajapur',
      'Sheopur',
      'Shivpuri',
      'Sidhi',
      'Singrauli',
      'Tikamgarh',
      'Ujjain',
      'Umaria',
      'Vidisha',
    ],

    'Maharashtra': <String>[
      'Ahmednagar',
      'Akola',
      'Amravati',
      'Aurangabad',
      'Beed',
      'Bhandara',
      'Buldhana',
      'Chandrapur',
      'Chhatrapati Sambhajinagar',
      'Dhule',
      'Gadchiroli',
      'Gondia',
      'Hingoli',
      'Jalgaon',
      'Jalna',
      'Kolhapur',
      'Latur',
      'Mumbai City',
      'Mumbai Suburban',
      'Nagpur',
      'Nanded',
      'Nandurbar',
      'Nashik',
      'Osmanabad',
      'Palghar',
      'Parbhani',
      'Pune',
      'Raigad',
      'Ratnagiri',
      'Sangli',
      'Satara',
      'Sindhudurg',
      'Solapur',
      'Thane',
      'Wardha',
      'Washim',
      'Yavatmal',
    ],

    'Manipur': <String>[
      'Bishnupur',
      'Chandel',
      'Churachandpur',
      'Imphal East',
      'Imphal West',
      'Jiribam',
      'Kakching',
      'Kamjong',
      'Kangpokpi',
      'Noney',
      'Pherzawl',
      'Senapati',
      'Tamenglong',
      'Tengnoupal',
      'Thoubal',
      'Ukhrul',
    ],

    'Meghalaya': <String>[
      'East Garo Hills',
      'East Jaintia Hills',
      'East Khasi Hills',
      'Eastern West Khasi Hills',
      'North Garo Hills',
      'Ri-Bhoi',
      'South Garo Hills',
      'South West Garo Hills',
      'South West Khasi Hills',
      'West Garo Hills',
      'West Jaintia Hills',
      'West Khasi Hills',
    ],

    'Mizoram': <String>[
      'Aizawl',
      'Champhai',
      'Hnahthial',
      'Khawzawl',
      'Kolasib',
      'Lawngtlai',
      'Lunglei',
      'Mamit',
      'Saiha',
      'Saitual',
      'Serchhip',
    ],

    'Nagaland': <String>[
      'Chumoukedima',
      'Dimapur',
      'Kiphire',
      'Kohima',
      'Longleng',
      'Mokokchung',
      'Mon',
      'Niuland',
      'Noklak',
      'Peren',
      'Phek',
      'Shamator',
      'Tuensang',
      'Tseminyu',
      'Wokha',
      'Zunheboto',
    ],

    'Odisha': <String>[
      'Angul',
      'Balangir',
      'Balasore',
      'Bargarh',
      'Bhadrak',
      'Boudh',
      'Cuttack',
      'Deogarh',
      'Dhenkanal',
      'Gajapati',
      'Ganjam',
      'Jagatsinghpur',
      'Jajpur',
      'Jharsuguda',
      'Kalahandi',
      'Kandhamal',
      'Kendrapara',
      'Kendujhar',
      'Khordha',
      'Koraput',
      'Malkangiri',
      'Mayurbhanj',
      'Nabarangpur',
      'Nayagarh',
      'Nuapada',
      'Puri',
      'Rayagada',
      'Sambalpur',
      'Subarnapur',
      'Sundargarh',
    ],

    'Punjab': <String>[
      'Amritsar',
      'Barnala',
      'Bathinda',
      'Faridkot',
      'Fatehgarh Sahib',
      'Fazilka',
      'Ferozepur',
      'Gurdaspur',
      'Hoshiarpur',
      'Jalandhar',
      'Kapurthala',
      'Ludhiana',
      'Malerkotla',
      'Mansa',
      'Moga',
      'Muktsar',
      'Pathankot',
      'Patiala',
      'Rupnagar',
      'Sahibzada Ajit Singh Nagar',
      'Sangrur',
      'Shaheed Bhagat Singh Nagar',
      'Tarn Taran',
    ],

    'Rajasthan': <String>[
      'Ajmer',
      'Alwar',
      'Anupgarh',
      'Balotra',
      'Banswara',
      'Baran',
      'Barmer',
      'Beawar',
      'Bharatpur',
      'Bhilwara',
      'Bikaner',
      'Bundi',
      'Chittorgarh',
      'Churu',
      'Dausa',
      'Deeg',
      'Dholpur',
      'Didwana-Kuchamana',
      'Dudu',
      'Dungarpur',
      'Gangapur City',
      'Hanumangarh',
      'Jaipur',
      'Jaisalmer',
      'Jalore',
      'Jhalawar',
      'Jhunjhunu',
      'Jodhpur',
      'Karauli',
      'Kekri',
      'Khairthal-Tijara',
      'Kota',
      'Kotputli-Behror',
      'Nagaur',
      'Neem Ka Thana',
      'Pali',
      'Phalodi',
      'Pratapgarh',
      'Rajsamand',
      'Salumbar',
      'Sawai Madhopur',
      'Shahpura',
      'Sikar',
      'Sirohi',
      'Sri Ganganagar',
      'Tonk',
      'Udaipur',
    ],

    'Sikkim': <String>[
      'Gangtok',
      'Gyalshing',
      'Mangan',
      'Namchi',
      'Pakyong',
      'Soreng',
    ],

    'Tamil Nadu': <String>[
      'Ariyalur',
      'Chengalpattu',
      'Chennai',
      'Coimbatore',
      'Cuddalore',
      'Dharmapuri',
      'Dindigul',
      'Erode',
      'Kallakurichi',
      'Kancheepuram',
      'Karur',
      'Krishnagiri',
      'Madurai',
      'Mayiladuthurai',
      'Nagapattinam',
      'Namakkal',
      'Nilgiris',
      'Perambalur',
      'Pudukkottai',
      'Ramanathapuram',
      'Ranipet',
      'Salem',
      'Sivaganga',
      'Tenkasi',
      'Thanjavur',
      'Theni',
      'Thoothukudi',
      'Tiruchirappalli',
      'Tirunelveli',
      'Tirupathur',
      'Tiruppur',
      'Tiruvallur',
      'Tiruvannamalai',
      'Tiruvarur',
      'Vellore',
      'Viluppuram',
      'Virudhunagar',
    ],

    'Telangana': <String>[
      'Adilabad',
      'Bhadradri Kothagudem',
      'Hanamkonda',
      'Hyderabad',
      'Jagtial',
      'Jangaon',
      'Jayashankar Bhupalpally',
      'Jogulamba Gadwal',
      'Kamareddy',
      'Karimnagar',
      'Khammam',
      'Komaram Bheem',
      'Mahabubabad',
      'Mahbubnagar',
      'Mancherial',
      'Medak',
      'Medchal-Malkajgiri',
      'Mulugu',
      'Nagarkurnool',
      'Nalgonda',
      'Narayanpet',
      'Nirmal',
      'Nizamabad',
      'Peddapalli',
      'Rajanna Sircilla',
      'Rangareddy',
      'Sangareddy',
      'Siddipet',
      'Suryapet',
      'Vikarabad',
      'Wanaparthy',
      'Warangal',
      'Yadadri Bhuvanagiri',
    ],

    'Tripura': <String>[
      'Dhalai',
      'Gomati',
      'Khowai',
      'North Tripura',
      'Sepahijala',
      'South Tripura',
      'Unakoti',
      'West Tripura',
    ],

    'Uttar Pradesh': <String>[
      'Agra',
      'Aligarh',
      'Ambedkar Nagar',
      'Amethi',
      'Amroha',
      'Auraiya',
      'Ayodhya',
      'Azamgarh',
      'Baghpat',
      'Bahraich',
      'Ballia',
      'Balrampur',
      'Banda',
      'Barabanki',
      'Bareilly',
      'Basti',
      'Bhadohi',
      'Bijnor',
      'Budaun',
      'Bulandshahr',
      'Chandauli',
      'Chitrakoot',
      'Deoria',
      'Etah',
      'Etawah',
      'Farrukhabad',
      'Fatehpur',
      'Firozabad',
      'Gautam Buddha Nagar',
      'Ghaziabad',
      'Ghazipur',
      'Gonda',
      'Gorakhpur',
      'Hamirpur',
      'Hapur',
      'Hardoi',
      'Hathras',
      'Jalaun',
      'Jaunpur',
      'Jhansi',
      'Kannauj',
      'Kanpur Dehat',
      'Kanpur Nagar',
      'Kasganj',
      'Kaushambi',
      'Kheri',
      'Kushinagar',
      'Lalitpur',
      'Lucknow',
      'Maharajganj',
      'Mahoba',
      'Mainpuri',
      'Mathura',
      'Mau',
      'Meerut',
      'Mirzapur',
      'Moradabad',
      'Muzaffarnagar',
      'Pilibhit',
      'Pratapgarh',
      'Prayagraj',
      'Raebareli',
      'Rampur',
      'Saharanpur',
      'Sambhal',
      'Sant Kabir Nagar',
      'Shahjahanpur',
      'Shamli',
      'Shravasti',
      'Siddharthnagar',
      'Sitapur',
      'Sonbhadra',
      'Sultanpur',
      'Unnao',
      'Varanasi',
    ],

    'Uttarakhand': <String>[
      'Almora',
      'Bageshwar',
      'Chamoli',
      'Champawat',
      'Dehradun',
      'Haridwar',
      'Nainital',
      'Pauri Garhwal',
      'Pithoragarh',
      'Rudraprayag',
      'Tehri Garhwal',
      'Udham Singh Nagar',
      'Uttarkashi',
    ],

    'West Bengal': <String>[
      'Alipurduar',
      'Bankura',
      'Paschim Bardhaman',
      'Purba Bardhaman',
      'Birbhum',
      'Cooch Behar',
      'Dakshin Dinajpur',
      'Darjeeling',
      'Hooghly',
      'Howrah',
      'Jalpaiguri',
      'Jhargram',
      'Kalimpong',
      'Kolkata',
      'Maldah',
      'Murshidabad',
      'Nadia',
      'North 24 Parganas',
      'South 24 Parganas',
      'Uttar Dinajpur',
      'Paschim Medinipur',
      'Purba Medinipur',
      'Purulia',
    ],
  };

  // ==========================================================
  // UNION TERRITORIES
  // ==========================================================

  static const Map<String, List<String>> unionTerritories =
      <String, List<String>>{
    'Andaman and Nicobar Islands': <String>[
      'Nicobar',
      'North and Middle Andaman',
      'South Andaman',
    ],
    'Chandigarh': <String>[
      'Chandigarh',
    ],
    'Dadra and Nagar Haveli and Daman and Diu':
        <String>[
      'Dadra and Nagar Haveli',
      'Daman',
      'Diu',
    ],
    'Delhi': <String>[
      'Central Delhi',
      'East Delhi',
      'New Delhi',
      'North Delhi',
      'North East Delhi',
      'North West Delhi',
      'Shahdara',
      'South Delhi',
      'South East Delhi',
      'South West Delhi',
      'West Delhi',
    ],
    'Jammu and Kashmir': <String>[
      'Anantnag',
      'Bandipora',
      'Baramulla',
      'Budgam',
      'Doda',
      'Ganderbal',
      'Jammu',
      'Kathua',
      'Kishtwar',
      'Kulgam',
      'Kupwara',
      'Poonch',
      'Pulwama',
      'Rajouri',
      'Ramban',
      'Reasi',
      'Samba',
      'Shopian',
      'Srinagar',
      'Udhampur',
    ],
    'Ladakh': <String>[
      'Kargil',
      'Leh',
    ],
    'Lakshadweep': <String>[
      'Lakshadweep',
    ],
    'Puducherry': <String>[
      'Karaikal',
      'Mahe',
      'Puducherry',
      'Yanam',
    ],
  };

  // ==========================================================
  // STATE LIST
  // ==========================================================

  List<String> get states {
    final List<String> result = <String>[
      ...stateDistricts.keys,
      ...unionTerritories.keys,
    ];

    result.sort();

    return result;
  }

  // ==========================================================
  // CURRENT DISTRICTS
  // ==========================================================

  List<String> get districts {
    final String state =
        widget.stateController.text.trim();

    if (state.isEmpty) {
      return <String>[];
    }

    return <String>[
      ...(stateDistricts[state] ??
          unionTerritories[state] ??
          <String>[]),
    ];
  }

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    widget.stateController.addListener(
      _stateControllerChanged,
    );
  }

  @override
  void dispose() {
    widget.stateController.removeListener(
      _stateControllerChanged,
    );

    super.dispose();
  }

  // ==========================================================
  // STATE CONTROLLER CHANGE
  // ==========================================================

  void _stateControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ==========================================================
  // STATE SELECTED
  // ==========================================================

  void _onStateChanged(String? value) {
    if (value == null || value.trim().isEmpty) {
      return;
    }

    widget.stateController.text = value;

    // State change = district must be selected again.
    widget.districtController.clear();

    setState(() {});
  }

  // ==========================================================
  // DISTRICT SELECTED
  // ==========================================================

  void _onDistrictChanged(String? value) {
    if (value == null || value.trim().isEmpty) {
      return;
    }

    widget.districtController.text = value;

    setState(() {});
  }

  // ==========================================================
  // NORMAL TEXT FIELD
  // ==========================================================

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        enabled: widget.enabled,
        keyboardType: keyboardType,
        maxLength: maxLength,
        textInputAction: TextInputAction.next,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.muted,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.blue,
          ),
          filled: true,
          fillColor: AppColors.surface,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.green,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DROPDOWN
  // ==========================================================

  Widget _dropdown({
  required String label,
  required IconData icon,
  required String? value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
  required String hint,
}) {
  final bool hasValidValue =
      value != null &&
      value.trim().isNotEmpty &&
      items.contains(value);

  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<String>(
      initialValue: hasValidValue ? value : null,
      isExpanded: true,
      onChanged: widget.enabled
          ? onChanged
          : null,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
      ),
      style: const TextStyle(
        color: AppColors.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: AppColors.muted,
        ),
        hintStyle: const TextStyle(
          color: AppColors.muted,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.blue,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.green,
            width: 1.5,
          ),
        ),
      ),
      items: items.map(
        (String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
    ),
  );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final String selectedState =
        widget.stateController.text.trim();

    final String selectedDistrict =
        widget.districtController.text.trim();

    final List<String> currentDistricts =
        districts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // HEADER
          // =====================================================

          const Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: AppColors.blue,
              ),
              SizedBox(width: 9),
              Text(
                'Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // =====================================================
          // VILLAGE
          // =====================================================

          _field(
            controller: widget.villageController,
            label: 'Village / Locality',
            icon: Icons.location_on_rounded,
          ),

          // =====================================================
          // CITY
          // =====================================================

          _field(
            controller: widget.cityController,
            label: 'City / Town',
            icon: Icons.location_city_rounded,
          ),

          // =====================================================
          // STATE DROPDOWN
          // =====================================================

          _dropdown(
            label: 'State',
            icon: Icons.public_rounded,
            value: selectedState,
            items: states,
            onChanged: _onStateChanged,
            hint: 'Select State',
          ),

          // =====================================================
          // DISTRICT DROPDOWN
          // =====================================================

          _dropdown(
            label: 'District',
            icon: Icons.map_rounded,
            value: selectedDistrict,
            items: currentDistricts,
            onChanged: _onDistrictChanged,
            hint: selectedState.isEmpty
                ? 'Select State first'
                : 'Select District',
          ),

          // =====================================================
          // PIN CODE
          // =====================================================

          _field(
            controller: widget.pinController,
            label: 'PIN Code',
            icon: Icons.pin_drop_rounded,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),

          // =====================================================
          // ADDRESS PREVIEW
          // =====================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.home_rounded,
                  color: AppColors.green,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    widget.fullAddress.isEmpty
                        ? 'Address preview'
                        : widget.fullAddress,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
