import 'dart:math';

/// 나라별 구(district) 단위 주소 목록
/// - 같은 도시라도 구마다 다른 좌표 → 중복 없는 다양한 배송지
/// - island: true 이면 섬 지역
/// - hasAirport: true 이면 국제공항 있는 섬
class CountryCities {
  static const Map<String, List<Map<String, dynamic>>> cities = {
    '대한민국': [
      {'name': '서울 강남구',   'lat': 37.5172, 'lng': 127.0473},
      {'name': '서울 마포구',   'lat': 37.5563, 'lng': 126.9023},
      {'name': '서울 종로구',   'lat': 37.5735, 'lng': 126.9790},
      {'name': '서울 성동구',   'lat': 37.5444, 'lng': 127.0557},
      {'name': '서울 송파구',   'lat': 37.5145, 'lng': 127.1059},
      {'name': '서울 용산구',   'lat': 37.5324, 'lng': 126.9900},
      {'name': '서울 서대문구', 'lat': 37.5791, 'lng': 126.9368},
      {'name': '서울 강동구',   'lat': 37.5301, 'lng': 127.1238},
      {'name': '서울 노원구',   'lat': 37.6549, 'lng': 127.0567},
      {'name': '서울 영등포구', 'lat': 37.5263, 'lng': 126.8963},
      {'name': '서울 광진구',   'lat': 37.5384, 'lng': 127.0822},
      {'name': '서울 동대문구', 'lat': 37.5744, 'lng': 127.0400},
      {'name': '부산 해운대구', 'lat': 35.1631, 'lng': 129.1639},
      {'name': '부산 남포동',   'lat': 35.0978, 'lng': 129.0348},
      {'name': '부산 서면',     'lat': 35.1572, 'lng': 129.0579},
      {'name': '부산 광안리',   'lat': 35.1531, 'lng': 129.1186},
      {'name': '부산 동래구',   'lat': 35.2061, 'lng': 129.0814},
      {'name': '부산 기장군',   'lat': 35.2448, 'lng': 129.2124},
      {'name': '부산 사상구',   'lat': 35.1494, 'lng': 128.9931},
      {'name': '부산 센텀시티', 'lat': 35.1669, 'lng': 129.1313},
      {'name': '인천 부평구',   'lat': 37.4897, 'lng': 126.7220},
      {'name': '인천 연수구',   'lat': 37.4100, 'lng': 126.6780},
      {'name': '인천 남동구',   'lat': 37.4487, 'lng': 126.7319},
      {'name': '인천 계양구',   'lat': 37.5376, 'lng': 126.7376},
      {'name': '대구 동성로',   'lat': 35.8694, 'lng': 128.5966},
      {'name': '대구 수성구',   'lat': 35.8587, 'lng': 128.6310},
      {'name': '대구 달서구',   'lat': 35.8291, 'lng': 128.5328},
      {'name': '대구 북구',     'lat': 35.8859, 'lng': 128.5826},
      {'name': '대전 유성구',   'lat': 36.3624, 'lng': 127.3566},
      {'name': '대전 서구',     'lat': 36.3551, 'lng': 127.3830},
      {'name': '대전 대덕구',   'lat': 36.3462, 'lng': 127.4149},
      {'name': '광주 북구',     'lat': 35.1741, 'lng': 126.9119},
      {'name': '광주 남구',     'lat': 35.1337, 'lng': 126.9023},
      {'name': '광주 동구',     'lat': 35.1461, 'lng': 126.9228},
      {'name': '수원 영통구',   'lat': 37.2556, 'lng': 127.0513},
      {'name': '수원 팔달구',   'lat': 37.2800, 'lng': 127.0090},
      {'name': '제주 제주시',   'lat': 33.4996, 'lng': 126.5312, 'island': true, 'hasAirport': true},
      {'name': '제주 서귀포시', 'lat': 33.2541, 'lng': 126.5602, 'island': true, 'hasAirport': true},
      {'name': '울산 남구',     'lat': 35.5384, 'lng': 129.3114},
      {'name': '울산 중구',     'lat': 35.5695, 'lng': 129.3320},
    ],
    '일본': [
      {'name': '도쿄 신주쿠',   'lat': 35.6938, 'lng': 139.7034},
      {'name': '도쿄 시부야',   'lat': 35.6580, 'lng': 139.7016},
      {'name': '도쿄 아키하바라','lat': 35.7022, 'lng': 139.7741},
      {'name': '도쿄 긴자',     'lat': 35.6717, 'lng': 139.7700},
      {'name': '도쿄 신오쿠보', 'lat': 35.7016, 'lng': 139.7003},
      {'name': '도쿄 아사쿠사', 'lat': 35.7148, 'lng': 139.7967},
      {'name': '도쿄 하라주쿠', 'lat': 35.6702, 'lng': 139.7025},
      {'name': '오사카 난바',   'lat': 34.6687, 'lng': 135.5019, 'island': false},
      {'name': '오사카 우메다', 'lat': 34.7024, 'lng': 135.4959},
      {'name': '오사카 신사이바시','lat': 34.6731, 'lng': 135.5014},
      {'name': '삿포로 스스키노','lat': 43.0551, 'lng': 141.3540, 'island': true, 'hasAirport': true},
      {'name': '삿포로 오도리', 'lat': 43.0618, 'lng': 141.3545, 'island': true, 'hasAirport': true},
      {'name': '후쿠오카 텐진', 'lat': 33.5904, 'lng': 130.4017},
      {'name': '후쿠오카 하카타','lat': 33.5890, 'lng': 130.4210},
      {'name': '나고야 사카에', 'lat': 35.1710, 'lng': 136.9072},
      {'name': '교토 기온',     'lat': 35.0036, 'lng': 135.7750},
      {'name': '교토 아라시야마','lat': 35.0095, 'lng': 135.6714},
      {'name': '고베 산노미야', 'lat': 34.6913, 'lng': 135.1956},
      {'name': '히로시마 나카구','lat': 34.3963, 'lng': 132.4596},
      {'name': '오키나와 나하', 'lat': 26.2124, 'lng': 127.6809, 'island': true, 'hasAirport': true},
      {'name': '오키나와 국제거리','lat': 26.2172, 'lng': 127.6885, 'island': true, 'hasAirport': true},
    ],
    '미국': [
      {'name': '뉴욕 맨해튼',   'lat': 40.7580, 'lng': -73.9855},
      {'name': '뉴욕 브루클린', 'lat': 40.6782, 'lng': -73.9442},
      {'name': '뉴욕 브롱크스', 'lat': 40.8448, 'lng': -73.8648},
      {'name': '뉴욕 퀸즈',     'lat': 40.7282, 'lng': -73.7949},
      {'name': 'LA 할리우드',   'lat': 34.0928, 'lng': -118.3287},
      {'name': 'LA 산타모니카', 'lat': 34.0195, 'lng': -118.4912},
      {'name': 'LA 베니스비치', 'lat': 33.9850, 'lng': -118.4695},
      {'name': 'LA 다운타운',   'lat': 34.0407, 'lng': -118.2468},
      {'name': '시카고 루프',   'lat': 41.8827, 'lng': -87.6233},
      {'name': '시카고 링컨파크','lat': 41.9242, 'lng': -87.6477},
      {'name': '샌프란시스코 미션','lat': 37.7599, 'lng': -122.4148},
      {'name': '샌프란시스코 SoMa','lat': 37.7785, 'lng': -122.3948},
      {'name': '샌프란시스코 차이나타운','lat': 37.7941, 'lng': -122.4078},
      {'name': '시애틀 파이크플레이스','lat': 47.6085, 'lng': -122.3406},
      {'name': '시애틀 캐피톨힐','lat': 47.6250, 'lng': -122.3138},
      {'name': '마이애미 사우스비치','lat': 25.7825, 'lng': -80.1300},
      {'name': '마이애미 코코넛그로브','lat': 25.7278, 'lng': -80.2385},
      {'name': '보스턴 백베이', 'lat': 42.3505, 'lng': -71.0785},
      {'name': '라스베이거스 스트립','lat': 36.1147, 'lng': -115.1728},
      {'name': '휴스턴 미드타운','lat': 29.7399, 'lng': -95.3838},
      {'name': '하와이 호놀룰루','lat': 21.3069, 'lng': -157.8583, 'island': true, 'hasAirport': true},
      {'name': '하와이 와이키키','lat': 21.2793, 'lng': -157.8294, 'island': true, 'hasAirport': true},
    ],
    '프랑스': [
      {'name': '파리 마레',     'lat': 48.8570, 'lng': 2.3520},
      {'name': '파리 몽마르트', 'lat': 48.8867, 'lng': 2.3431},
      {'name': '파리 생제르망', 'lat': 48.8535, 'lng': 2.3336},
      {'name': '파리 바스티유', 'lat': 48.8533, 'lng': 2.3692},
      {'name': '파리 오페라',   'lat': 48.8718, 'lng': 2.3320},
      {'name': '파리 레알',     'lat': 48.8620, 'lng': 2.3470},
      {'name': '마르세유 비유포르','lat': 43.2951, 'lng': 5.3748},
      {'name': '리옹 벨꾸르',   'lat': 45.7597, 'lng': 4.8327},
      {'name': '니스 프롬나드', 'lat': 43.6961, 'lng': 7.2659},
      {'name': '보르도 메리아독','lat': 44.8400, 'lng': -0.5792},
    ],
    '영국': [
      {'name': '런던 소호',     'lat': 51.5137, 'lng': -0.1337},
      {'name': '런던 캠든',     'lat': 51.5390, 'lng': -0.1426},
      {'name': '런던 쇼디치',   'lat': 51.5228, 'lng': -0.0780},
      {'name': '런던 노팅힐',   'lat': 51.5138, 'lng': -0.1975},
      {'name': '런던 그리니치', 'lat': 51.4834, 'lng': -0.0099},
      {'name': '런던 브리지턴', 'lat': 51.4613, 'lng': -0.1156},
      {'name': '맨체스터 노던쿼터','lat': 53.4841, 'lng': -2.2367},
      {'name': '에딘버러 올드타운','lat': 55.9488, 'lng': -3.1964},
      {'name': '글래스고 웨스트엔드','lat': 55.8733, 'lng': -4.2890},
      {'name': '리버풀 알버트독','lat': 53.4017, 'lng': -2.9960},
    ],
    '독일': [
      {'name': '베를린 미테',   'lat': 52.5200, 'lng': 13.4050},
      {'name': '베를린 프렌츠라우어베르크','lat': 52.5381, 'lng': 13.4175},
      {'name': '베를린 크로이츠베르크','lat': 52.4994, 'lng': 13.4026},
      {'name': '뮌헨 마리엔플라츠','lat': 48.1374, 'lng': 11.5755},
      {'name': '뮌헨 슈바빙',   'lat': 48.1598, 'lng': 11.5707},
      {'name': '함부르크 레퍼반','lat': 53.5496, 'lng': 9.9645},
      {'name': '함부르크 항구도시','lat': 53.5426, 'lng': 9.9988},
      {'name': '프랑크푸르트 자흐센하우젠','lat': 50.0990, 'lng': 8.6820},
      {'name': '쾰른 알트슈타트','lat': 50.9383, 'lng': 6.9603},
    ],
    '이탈리아': [
      {'name': '로마 트라스테베레','lat': 41.8892, 'lng': 12.4693},
      {'name': '로마 나보나광장','lat': 41.8990, 'lng': 12.4732},
      {'name': '로마 트레비분수','lat': 41.9009, 'lng': 12.4833},
      {'name': '밀라노 두오모', 'lat': 45.4641, 'lng': 9.1920},
      {'name': '밀라노 나빌리', 'lat': 45.4524, 'lng': 9.1755},
      {'name': '나폴리 스파카',  'lat': 40.8500, 'lng': 14.2548},
      {'name': '베네치아 산마르코','lat': 45.4343, 'lng': 12.3388, 'island': true, 'hasAirport': true},
      {'name': '피렌체 두오모', 'lat': 43.7731, 'lng': 11.2560},
    ],
    '스페인': [
      {'name': '마드리드 말라사냐','lat': 40.4246, 'lng': -3.7084},
      {'name': '마드리드 라바피에스','lat': 40.4072, 'lng': -3.7035},
      {'name': '바르셀로나 고딕','lat': 41.3825, 'lng': 2.1769},
      {'name': '바르셀로나 그라시아','lat': 41.3985, 'lng': 2.1531},
      {'name': '바르셀로나 포블레노우','lat': 41.4036, 'lng': 2.1993},
      {'name': '세비야 트리아나','lat': 37.3877, 'lng': -5.9975},
      {'name': '발렌시아 카르멘','lat': 39.4778, 'lng': -0.3796},
    ],
    '브라질': [
      {'name': '상파울루 빌라마달레나','lat': -23.5567, 'lng': -46.6891},
      {'name': '상파울루 이타임비비','lat': -23.5874, 'lng': -46.6814},
      {'name': '상파울루 피냐이로스','lat': -23.5665, 'lng': -46.6865},
      {'name': '리우 코파카바나','lat': -22.9714, 'lng': -43.1860},
      {'name': '리우 이파네마', 'lat': -22.9838, 'lng': -43.2096},
      {'name': '리우 레블론',   'lat': -22.9861, 'lng': -43.2257},
      {'name': '브라질리아 아사수르','lat': -15.7942, 'lng': -47.8825},
    ],
    '인도': [
      {'name': '뉴델리 코노트플레이스','lat': 28.6315, 'lng': 77.2167},
      {'name': '뉴델리 하우즈카스','lat': 28.5494, 'lng': 77.2001},
      {'name': '뭄바이 반드라', 'lat': 19.0543, 'lng': 72.8405},
      {'name': '뭄바이 콜라바', 'lat': 18.9067, 'lng': 72.8147},
      {'name': '방갈로르 코라만갈라','lat': 12.9279, 'lng': 77.6271},
      {'name': '방갈로르 인디라나가르','lat': 12.9784, 'lng': 77.6408},
      {'name': '콜카타 파크스트리트','lat': 22.5526, 'lng': 88.3519},
      {'name': '첸나이 T나가르','lat': 13.0418, 'lng': 80.2341},
    ],
    '중국': [
      {'name': '베이징 싼리툰', 'lat': 39.9332, 'lng': 116.4575},
      {'name': '베이징 후통',   'lat': 39.9350, 'lng': 116.3873},
      {'name': '상하이 신티엔디','lat': 31.2207, 'lng': 121.4728},
      {'name': '상하이 와이탄', 'lat': 31.2369, 'lng': 121.4896},
      {'name': '상하이 루자쭈이','lat': 31.2397, 'lng': 121.4990},
      {'name': '광저우 티엔허', 'lat': 23.1279, 'lng': 113.3265},
      {'name': '선전 난산',     'lat': 22.5431, 'lng': 113.9461},
      {'name': '청두 진리',     'lat': 30.6580, 'lng': 104.0600},
    ],
    '호주': [
      {'name': '시드니 서리힐스','lat': -33.8853, 'lng': 151.2094},
      {'name': '시드니 뉴타운', 'lat': -33.8987, 'lng': 151.1786},
      {'name': '시드니 본다이비치','lat': -33.8915, 'lng': 151.2767},
      {'name': '시드니 포츠포인트','lat': -33.8744, 'lng': 151.2230},
      {'name': '멜버른 피츠로이','lat': -37.8002, 'lng': 144.9790},
      {'name': '멜버른 세인트킬다','lat': -37.8607, 'lng': 144.9813},
      {'name': '멜버른 CBD',    'lat': -37.8136, 'lng': 144.9631},
      {'name': '브리즈번 포티튜드밸리','lat': -27.4597, 'lng': 153.0351},
      {'name': '퍼스 프리맨틀', 'lat': -32.0569, 'lng': 115.7439},
    ],
    '캐나다': [
      {'name': '토론토 킹스트웨스트','lat': 43.6440, 'lng': -79.4002},
      {'name': '토론토 케아볼리지','lat': 43.6535, 'lng': -79.3696},
      {'name': '토론토 키치너', 'lat': 43.4503, 'lng': -80.4981},
      {'name': '밴쿠버 개스타운','lat': 49.2839, 'lng': -123.1091},
      {'name': '밴쿠버 킷실라노','lat': 49.2697, 'lng': -123.1672},
      {'name': '몬트리올 플라토','lat': 45.5247, 'lng': -73.5803},
      {'name': '몬트리올 마일엔드','lat': 45.5219, 'lng': -73.5979},
    ],
    '멕시코': [
      {'name': '멕시코시티 콘데사','lat': 19.4138, 'lng': -99.1749},
      {'name': '멕시코시티 로마','lat': 19.4193, 'lng': -99.1621},
      {'name': '멕시코시티 코요아칸','lat': 19.3544, 'lng': -99.1627},
      {'name': '과달라하라 차풀테펙','lat': 20.6736, 'lng': -103.4069},
      {'name': '몬테레이 산페드로','lat': 25.6587, 'lng': -100.4034},
    ],
    '아르헨티나': [
      {'name': '부에노스아이레스 팔레르모','lat': -34.5871, 'lng': -58.4263},
      {'name': '부에노스아이레스 산텔모','lat': -34.6209, 'lng': -58.3685},
      {'name': '부에노스아이레스 레콜레타','lat': -34.5875, 'lng': -58.3935},
      {'name': '코르도바 누에바코르도바','lat': -31.4105, 'lng': -64.1873},
    ],
    '러시아': [
      {'name': '모스크바 아르바트','lat': 55.7520, 'lng': 37.5960},
      {'name': '모스크바 쿨투르나야','lat': 55.7302, 'lng': 37.6255},
      {'name': '상트페테르부르크 넵스키','lat': 59.9308, 'lng': 30.3644},
      {'name': '블라디보스토크 중앙광장','lat': 43.1155, 'lng': 131.8855},
    ],
    '터키': [
      {'name': '이스탄불 베식타스','lat': 41.0435, 'lng': 29.0042},
      {'name': '이스탄불 카디쾨이','lat': 40.9910, 'lng': 29.0254},
      {'name': '이스탄불 탁심',  'lat': 41.0366, 'lng': 28.9850},
      {'name': '이스탄불 그랜드바자','lat': 41.0109, 'lng': 28.9681},
      {'name': '앙카라 키질라이', 'lat': 39.9209, 'lng': 32.8541},
    ],
    '이집트': [
      {'name': '카이로 자말렉',  'lat': 30.0626, 'lng': 31.2195},
      {'name': '카이로 마아디',  'lat': 29.9597, 'lng': 31.2565},
      {'name': '알렉산드리아 스탠리','lat': 31.2194, 'lng': 29.9432},
    ],
    '남아프리카': [
      {'name': '요하네스버그 멜빌','lat': -26.1840, 'lng': 27.9986},
      {'name': '요하네스버그 샌드튼','lat': -26.1070, 'lng': 28.0555},
      {'name': '케이프타운 볼더스비치','lat': -34.1978, 'lng': 18.4534},
      {'name': '케이프타운 그린포인트','lat': -33.9066, 'lng': 18.4106},
    ],
    '태국': [
      {'name': '방콕 아속',     'lat': 13.7447, 'lng': 100.5601},
      {'name': '방콕 씰롬',     'lat': 13.7254, 'lng': 100.5313},
      {'name': '방콕 짜뚜짝',   'lat': 13.7997, 'lng': 100.5500},
      {'name': '방콕 카오산로드','lat': 13.7590, 'lng': 100.4981},
      {'name': '치앙마이 님만헤민','lat': 18.8014, 'lng': 98.9695},
      {'name': '푸켓 빠통비치', 'lat': 7.8951, 'lng': 98.2975, 'island': true, 'hasAirport': true},
      {'name': '푸켓 올드타운', 'lat': 7.8793, 'lng': 98.3928, 'island': true, 'hasAirport': true},
    ],
    '네덜란드': [
      {'name': '암스테르담 요르단','lat': 52.3757, 'lng': 4.8833},
      {'name': '암스테르담 데피프','lat': 52.3600, 'lng': 4.8780},
      {'name': '로테르담 바인하번','lat': 51.9132, 'lng': 4.4749},
      {'name': '헤이그 스헤베닝언','lat': 52.1050, 'lng': 4.2722},
    ],
    '스웨덴': [
      {'name': '스톡홀름 쇠데르말름','lat': 59.3183, 'lng': 18.0677},
      {'name': '스톡홀름 감라스탄','lat': 59.3253, 'lng': 18.0715},
      {'name': '예테보리 린네가탄','lat': 57.6954, 'lng': 11.9549},
    ],
    '노르웨이': [
      {'name': '오슬로 그뤼네를뢰카','lat': 59.9225, 'lng': 10.7617},
      {'name': '오슬로 아케르브뤼게','lat': 59.9111, 'lng': 10.7318},
      {'name': '베르겐 브뤼겐',  'lat': 60.3970, 'lng': 5.3241},
    ],
    '포르투갈': [
      {'name': '리스본 알파마',  'lat': 38.7141, 'lng': -9.1327},
      {'name': '리스본 바이루알투','lat': 38.7148, 'lng': -9.1490},
      {'name': '포르투 히베이라','lat': 41.1413, 'lng': -8.6144},
      {'name': '포르투 빌라노바','lat': 41.1369, 'lng': -8.6067},
    ],
    '인도네시아': [
      {'name': '자카르타 슐탄이스칸다르','lat': -6.1869, 'lng': 106.8340},
      {'name': '자카르타 플루잇','lat': -6.1235, 'lng': 106.7878},
      {'name': '발리 꾸따',     'lat': -8.7195, 'lng': 115.1686, 'island': true, 'hasAirport': true},
      {'name': '발리 세미냑',   'lat': -8.6934, 'lng': 115.1575, 'island': true, 'hasAirport': true},
      {'name': '발리 우붓',     'lat': -8.5069, 'lng': 115.2625, 'island': true, 'hasAirport': true},
      {'name': '수라바야 군둥사리','lat': -7.2491, 'lng': 112.7688},
    ],
    '말레이시아': [
      {'name': '쿠알라룸푸르 부킷빈탕','lat': 3.1483, 'lng': 101.7119},
      {'name': '쿠알라룸푸르 KLCC','lat': 3.1579, 'lng': 101.7123},
      {'name': '페낭 조지타운', 'lat': 5.4145, 'lng': 100.3292, 'island': true, 'hasAirport': true},
      {'name': '코타키나발루 센터포인트','lat': 5.9770, 'lng': 116.0724},
    ],
    '싱가포르': [
      {'name': '싱가포르 마리나베이','lat': 1.2838, 'lng': 103.8591, 'island': true, 'hasAirport': true},
      {'name': '싱가포르 차이나타운','lat': 1.2835, 'lng': 103.8444, 'island': true, 'hasAirport': true},
      {'name': '싱가포르 리틀인디아','lat': 1.3065, 'lng': 103.8516, 'island': true, 'hasAirport': true},
      {'name': '싱가포르 캄퐁글람','lat': 1.3039, 'lng': 103.8597, 'island': true, 'hasAirport': true},
    ],
    '뉴질랜드': [
      {'name': '오클랜드 폰슨비','lat': -36.8645, 'lng': 174.7432},
      {'name': '오클랜드 파넬',  'lat': -36.8596, 'lng': 174.7784},
      {'name': '웰링턴 테아로','lat': -41.2951, 'lng': 174.7788},
      {'name': '크라이스트처치 리카튼','lat': -43.5302, 'lng': 172.5980},
    ],
    '필리핀': [
      {'name': '마닐라 마카티', 'lat': 14.5547, 'lng': 121.0244},
      {'name': '마닐라 BGC',    'lat': 14.5490, 'lng': 121.0490},
      {'name': '세부 IT파크',   'lat': 10.3310, 'lng': 123.9065, 'island': true, 'hasAirport': true},
      {'name': '세부 코론',     'lat': 10.3201, 'lng': 123.8978, 'island': true, 'hasAirport': true},
      {'name': '보라카이 화이트비치','lat': 11.9674, 'lng': 121.9248, 'island': true, 'hasAirport': true},
    ],
    '베트남': [
      {'name': '하노이 호안끼엠','lat': 21.0340, 'lng': 105.8521},
      {'name': '하노이 떠이호',  'lat': 21.0526, 'lng': 105.8238},
      {'name': '호치민 1군',    'lat': 10.7826, 'lng': 106.6980},
      {'name': '호치민 푸미흥', 'lat': 10.7212, 'lng': 106.7141},
      {'name': '다낭 미케비치', 'lat': 16.0544, 'lng': 108.2477},
    ],
    '그리스': [
      {'name': '아테네 모나스티라키','lat': 37.9755, 'lng': 23.7243},
      {'name': '아테네 엑사르헤이아','lat': 37.9875, 'lng': 23.7313},
      {'name': '산토리니 피라', 'lat': 36.4165, 'lng': 25.4321, 'island': true, 'hasAirport': true},
      {'name': '산토리니 오이아','lat': 36.4618, 'lng': 25.3760, 'island': true, 'hasAirport': true},
    ],
    '이스라엘': [
      {'name': '텔아비브 플로렌틴','lat': 32.0574, 'lng': 34.7706},
      {'name': '텔아비브 로스차일드','lat': 32.0632, 'lng': 34.7752},
      {'name': '예루살렘 구시가','lat': 31.7781, 'lng': 35.2293},
    ],
    '사우디아라비아': [
      {'name': '리야드 킹덤센터','lat': 24.6887, 'lng': 46.6826},
      {'name': '리야드 디리야',  'lat': 24.7349, 'lng': 46.5734},
      {'name': '제다 알발라드', 'lat': 21.4858, 'lng': 39.1925},
    ],
    'UAE': [
      {'name': '두바이 마리나',  'lat': 25.0801, 'lng': 55.1396},
      {'name': '두바이 다운타운','lat': 25.1972, 'lng': 55.2744},
      {'name': '두바이 JLT',    'lat': 25.0731, 'lng': 55.1410},
      {'name': '아부다비 코니쉬','lat': 24.4653, 'lng': 54.3518},
    ],
    '파키스탄': [
      {'name': '카라치 DHA',    'lat': 24.7921, 'lng': 67.0613},
      {'name': '라호르 걸버그', 'lat': 31.5204, 'lng': 74.3587},
    ],
    '방글라데시': [
      {'name': '다카 굴샨',     'lat': 23.7924, 'lng': 90.4148},
      {'name': '다카 다한몬디', 'lat': 23.7461, 'lng': 90.3742},
    ],
    '나이지리아': [
      {'name': '라고스 빅토리아아일랜드','lat': 6.4280, 'lng': 3.4219, 'island': true, 'hasAirport': true},
      {'name': '라고스 이코이',  'lat': 6.4546, 'lng': 3.4341},
      {'name': '아부자 가르키',  'lat': 9.0765, 'lng': 7.4922},
    ],
    '케냐': [
      {'name': '나이로비 웨스트랜즈','lat': -1.2648, 'lng': 36.8071},
      {'name': '몸바사 냐리구국','lat': -4.0435, 'lng': 39.6682},
    ],
    '에티오피아': [
      {'name': '아디스아바바 볼레','lat': 9.0193, 'lng': 38.7990},
      {'name': '아디스아바바 피아사','lat': 9.0320, 'lng': 38.7469},
    ],
    '모로코': [
      {'name': '카사블랑카 안파','lat': 33.5975, 'lng': -7.6328},
      {'name': '마라케시 제마알프나','lat': 31.6258, 'lng': -7.9892},
      {'name': '페스 메디나',    'lat': 34.0653, 'lng': -4.9748},
    ],
    '콜롬비아': [
      {'name': '보고타 라칸델라리아','lat': 4.5975, 'lng': -74.0763},
      {'name': '메데인 엘포블라도','lat': 6.2094, 'lng': -75.5682},
    ],
    '페루': [
      {'name': '리마 미라플로레스','lat': -18.1186, 'lng': -70.0341},
      {'name': '리마 바랑코',   'lat': -12.1519, 'lng': -77.0228},
      {'name': '쿠스코 플라자',  'lat': -13.5159, 'lng': -71.9779},
    ],
    '칠레': [
      {'name': '산티아고 라스콘데스','lat': -33.4098, 'lng': -70.5681},
      {'name': '산티아고 벨라비스타','lat': -33.4348, 'lng': -70.6347},
      {'name': '발파라이소 체로알레그레','lat': -33.0472, 'lng': -71.6127},
    ],
    '덴마크': [
      {'name': '코펜하겐 노르드하운','lat': 55.6935, 'lng': 12.5990},
      {'name': '코펜하겐 크리스티아니아','lat': 55.6730, 'lng': 12.5958},
    ],
    '핀란드': [
      {'name': '헬싱키 깔리오',  'lat': 60.1837, 'lng': 24.9497},
      {'name': '헬싱키 푸나부오리','lat': 60.1657, 'lng': 24.9421},
    ],
    '오스트리아': [
      {'name': '빈 7구 노이바우','lat': 48.2034, 'lng': 16.3546},
      {'name': '빈 1구 이너슈타트','lat': 48.2082, 'lng': 16.3738},
      {'name': '잘츠부르크 알트슈타트','lat': 47.7991, 'lng': 13.0443},
    ],
    '폴란드': [
      {'name': '바르샤바 쉬로드미에스치에','lat': 52.2366, 'lng': 21.0122},
      {'name': '크라쿠프 구시가','lat': 50.0621, 'lng': 19.9366},
    ],
    '체코': [
      {'name': '프라하 말라스트라나','lat': 50.0874, 'lng': 14.4032},
      {'name': '프라하 지즈코프','lat': 50.0846, 'lng': 14.4502},
    ],
    '헝가리': [
      {'name': '부다페스트 유대인지구','lat': 47.4993, 'lng': 19.0619},
      {'name': '부다페스트 로지','lat': 47.4936, 'lng': 19.0528},
    ],
    '우크라이나': [
      {'name': '키이우 포딜',   'lat': 50.4626, 'lng': 30.5166},
      {'name': '키이우 페체르스크','lat': 50.4274, 'lng': 30.5588},
    ],
  };

  /// 국제공항이 있는 섬 도시 (항공 배송)
  static bool isIslandWithAirport(String cityName) {
    final c = cities.values
        .expand((list) => list)
        .where((m) => m['name'] == cityName)
        .firstOrNull;
    return c != null &&
        (c['island'] == true) &&
        (c['hasAirport'] == true);
  }

  /// 섬 도시 여부 (공항 유무 불문)
  static bool isIslandCity(String cityName) {
    final c = cities.values
        .expand((list) => list)
        .where((m) => m['name'] == cityName)
        .firstOrNull;
    return c != null && (c['island'] == true);
  }

  /// 나라의 랜덤 구/지역 반환 (사용된 주소 제외)
  static Map<String, dynamic>? randomCity(
    String country, {
    Set<String>? usedCityKeys,
  }) {
    final rng = Random();
    final list = cities[country];
    if (list == null || list.isEmpty) return null;

    final available = usedCityKeys != null
        ? list
            .where((c) => !usedCityKeys.contains('${country}_${c['name']}'))
            .toList()
        : list;

    if (available.isEmpty) return list[rng.nextInt(list.length)];
    return available[rng.nextInt(available.length)];
  }

  /// 도시 키 생성
  static String cityKey(String country, String cityName) =>
      '${country}_$cityName';

  /// 실제 주소처럼 보이게 ±80m 이내 랜덤 오프셋 적용
  /// 위도 1° ≈ 111,000m  →  0.00072° ≈ 80m
  /// 경도 1° ≈ 111,000 * cos(lat) m
  static Map<String, dynamic> withStreetOffset(Map<String, dynamic> city) {
    final rng = Random();
    const maxDeg = 0.00072; // ≈ 80m
    final lat = (city['lat'] as num).toDouble();
    final lng = (city['lng'] as num).toDouble();
    final cosLat = cos(lat * pi / 180);
    return {
      ...city,
      'lat': lat + (rng.nextDouble() * 2 - 1) * maxDeg,
      'lng': lng + (rng.nextDouble() * 2 - 1) * maxDeg / (cosLat == 0 ? 1 : cosLat),
    };
  }

  /// 나라의 랜덤 구/지역 반환 (가로단위 오프셋 포함, 사용된 주소 제외)
  static Map<String, dynamic>? randomCityWithOffset(
    String country, {
    Set<String>? usedCityKeys,
  }) {
    final base = randomCity(country, usedCityKeys: usedCityKeys);
    if (base == null) return null;
    return withStreetOffset(base);
  }
}

// ── 전 세계 육지 유효 주소 생성기 ──────────────────────────────────────────────
/// Node.js의 랜덤 배송지 생성 함수를 Dart로 포팅한 버전.
/// Nominatim API 대신 내장 도시 DB로 육지 유효성 검증.
///
/// 동작 원리:
/// 1. 나라별 육지 경계(countryBounds)에서 랜덤 위경도 생성
/// 2. 생성된 좌표가 가장 가까운 도시에서 200km 이내인지 확인
/// 3. 유효하면 ±80m 거리 오프셋 추가 (실제 주소처럼)
/// 4. 유효하지 않으면(바다 등) 최대 10회 재시도
class LandAddressGenerator {
  static final _rng = Random();

  /// 나라별 육지 경계 박스 (minLat, maxLat, minLng, maxLng)
  /// Node.js countryBounds와 동일한 개념
  static const List<_CountryBound> countryBounds = [
    _CountryBound('대한민국',     34.0, 38.5,  126.0, 129.5),
    _CountryBound('일본',         30.5, 45.5,  130.0, 145.5),
    _CountryBound('미국',         25.0, 49.0, -125.0, -66.0),
    _CountryBound('프랑스',       42.0, 51.1,   -5.0,   8.5),
    _CountryBound('영국',         50.0, 58.7,   -6.0,   2.0),
    _CountryBound('독일',         47.3, 55.0,    6.0,  15.0),
    _CountryBound('이탈리아',     37.0, 47.1,    6.5,  18.5),
    _CountryBound('스페인',       36.0, 43.8,   -9.3,   3.3),
    _CountryBound('브라질',      -33.5,  5.3,  -73.5, -35.0),
    _CountryBound('인도',          8.0, 35.5,   68.0,  97.5),
    _CountryBound('중국',         18.0, 53.5,   73.5, 135.0),
    _CountryBound('호주',        -43.5, -10.5, 114.0, 153.5),
    _CountryBound('캐나다',       42.0,  83.0, -141.0, -52.0),
    _CountryBound('멕시코',       14.5,  32.7, -118.0, -86.5),
    _CountryBound('아르헨티나',  -55.0, -22.0,  -73.5, -53.5),
    _CountryBound('러시아',       41.0,  77.5,   27.0, 180.0),
    _CountryBound('터키',         36.0,  42.1,   26.0,  45.0),
    _CountryBound('이집트',       22.0,  31.7,   25.0,  37.0),
    _CountryBound('태국',          5.5,  20.5,   97.5, 105.6),
    _CountryBound('네덜란드',     50.7,  53.6,    3.3,   7.2),
    _CountryBound('스웨덴',       55.3,  69.0,   10.5,  24.1),
    _CountryBound('포르투갈',     36.9,  42.2,   -9.5,  -6.1),
    _CountryBound('인도네시아',   -8.8,   5.9,   95.0, 141.0),
    _CountryBound('말레이시아',    1.0,   7.3,  100.0, 119.3),
    _CountryBound('싱가포르',      1.2,   1.5,  103.6, 104.0),
    _CountryBound('필리핀',        5.0,  19.5,  117.0, 127.0),
    _CountryBound('베트남',        8.3,  23.4,  102.1, 109.5),
    _CountryBound('폴란드',       49.0,  54.9,   14.1,  24.2),
    _CountryBound('그리스',       34.8,  41.8,   20.0,  28.3),
    _CountryBound('UAE',          22.6,  26.1,   51.5,  56.4),
  ];

  /// 전 세계 랜덤 유효 육지 주소 생성
  /// [excludeCountry] 제외할 나라 이름
  /// 반환: {'name': 주소명, 'lat': 위도, 'lng': 경도, 'country': 나라명}
  static Map<String, dynamic> generate({String? excludeCountry, int maxRetries = 10}) {
    final pool = excludeCountry != null
        ? countryBounds.where((b) => b.country != excludeCountry).toList()
        : countryBounds;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      // 1. 랜덤 나라 경계 선택
      final bound = pool[_rng.nextInt(pool.length)];

      // 2. 경계 내 랜덤 위경도 생성
      final lat = bound.minLat + _rng.nextDouble() * (bound.maxLat - bound.minLat);
      final lng = bound.minLng + _rng.nextDouble() * (bound.maxLng - bound.minLng);

      // 3. 가장 가까운 도시 찾아서 육지 검증 (200km 이내)
      final nearest = _findNearestCity(lat, lng, bound.country);
      if (nearest != null) {
        // 4. 유효한 육지 좌표 → ±500m 오프셋 추가 (실제 주소 범위)
        const maxDeg = 0.0045; // ≈ 500m
        final cosLat = cos(lat * pi / 180);
        return {
          'name': nearest['name'],
          'lat': lat + (_rng.nextDouble() * 2 - 1) * maxDeg,
          'lng': lng + (_rng.nextDouble() * 2 - 1) * maxDeg / (cosLat == 0 ? 1 : cosLat),
          'country': bound.country,
          'flag': _countryFlag(bound.country),
        };
      }
      // 실패 시 재시도 (바다 또는 알 수 없는 지역)
    }

    // 최대 재시도 초과 → 해당 나라의 DB에서 직접 랜덤 픽
    final fallbackBound = pool[_rng.nextInt(pool.length)];
    final fallback = CountryCities.randomCityWithOffset(fallbackBound.country);
    if (fallback != null) {
      return {
        ...fallback,
        'country': fallbackBound.country,
        'flag': _countryFlag(fallbackBound.country),
      };
    }
    return {'name': '서울 강남구', 'lat': 37.5172, 'lng': 127.0473, 'country': '대한민국', 'flag': '🇰🇷'};
  }

  /// 주어진 좌표에서 해당 나라 도시 DB의 가장 가까운 도시 반환 (200km 이내)
  static Map<String, dynamic>? _findNearestCity(double lat, double lng, String country) {
    final list = CountryCities.cities[country];
    if (list == null || list.isEmpty) return null;

    Map<String, dynamic>? nearest;
    double minDist = double.infinity;

    for (final city in list) {
      final cLat = (city['lat'] as num).toDouble();
      final cLng = (city['lng'] as num).toDouble();
      final dist = _haversineKm(lat, lng, cLat, cLng);
      if (dist < minDist) {
        minDist = dist;
        nearest = city;
      }
    }
    // 200km 이내면 육지로 간주
    return minDist <= 200.0 ? nearest : null;
  }

  /// Haversine 거리 계산 (km)
  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static String _countryFlag(String country) {
    const flags = {
      '대한민국': '🇰🇷', '일본': '🇯🇵', '미국': '🇺🇸', '프랑스': '🇫🇷', '영국': '🇬🇧',
      '독일': '🇩🇪', '이탈리아': '🇮🇹', '스페인': '🇪🇸', '브라질': '🇧🇷', '인도': '🇮🇳',
      '중국': '🇨🇳', '호주': '🇦🇺', '캐나다': '🇨🇦', '멕시코': '🇲🇽', '아르헨티나': '🇦🇷',
      '러시아': '🇷🇺', '터키': '🇹🇷', '이집트': '🇪🇬', '태국': '🇹🇭', '네덜란드': '🇳🇱',
      '스웨덴': '🇸🇪', '포르투갈': '🇵🇹', '인도네시아': '🇮🇩', '말레이시아': '🇲🇾',
      '싱가포르': '🇸🇬', '필리핀': '🇵🇭', '베트남': '🇻🇳', '폴란드': '🇵🇱', '그리스': '🇬🇷',
      'UAE': '🇦🇪',
    };
    return flags[country] ?? '🌍';
  }
}

/// 나라 육지 경계 박스 데이터 클래스
class _CountryBound {
  final String country;
  final double minLat, maxLat, minLng, maxLng;
  const _CountryBound(this.country, this.minLat, this.maxLat, this.minLng, this.maxLng);
}
