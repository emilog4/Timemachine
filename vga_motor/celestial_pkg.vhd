library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package celestial_pkg is
    -- Koordinat-tabeller
    type coord_array is array (0 to 255) of integer;

    constant SUN_X_LUT : coord_array := (
        640,  637,  634,  631,  628,  625,  622,  619,
        616,  613,  610,  607,  604,  601,  598,  595,
        592,  589,  586,  583,  580,  577,  574,  571,
        568,  565,  562,  559,  556,  553,  550,  547,
        544,  541,  538,  535,  532,  529,  526,  523,
        520,  517,  514,  511,  508,  505,  502,  499,
        496,  493,  490,  487,  484,  481,  478,  475,
        472,  469,  466,  463,  460,  457,  454,  451,
        448,  445,  442,  439,  436,  433,  430,  427,
        424,  421,  418,  415,  412,  409,  406,  403,
        400,  397,  394,  391,  388,  385,  382,  379,
        376,  373,  370,  367,  364,  361,  358,  355,
        352,  349,  346,  343,  340,  337,  334,  331,
        328,  325,  322,  319,  316,  313,  310,  307,
        304,  301,  298,  295,  292,  289,  286,  283,
        280,  277,  274,  271,  268,  265,  262,  259,
        256,  253,  250,  247,  244,  241,  238,  235,
        232,  229,  226,  223,  220,  217,  214,  211,
        208,  205,  202,  199,  196,  193,  190,  187,
        184,  181,  178,  175,  172,  169,  166,  163,
        160,  157,  154,  151,  148,  145,  142,  139,
        136,  133,  130,  127,  124,  121,  118,  115,
        112,  109,  106,  103,  100,   97,   94,   91,
        88,   85,   82,   79,   76,   73,   70,   67,
        64,   61,   58,   55,   52,   49,   46,   43,
        40,   37,   34,   31,   28,   25,   22,   19,
        16,   13,   10,    7,    4,    1,   -2,   -5,
        -8,  -11,  -14,  -17,  -20,  -23,  -26,  -29,
        -32,  -35,  -38,  -41,  -44,  -47,  -50,  -53,
        -56,  -59,  -62,  -65,  -68,  -71,  -74,  -77,
        -80,  -83,  -86,  -89,  -92,  -95,  -98, -101,
        -104, -107, -110, -113, -116, -119, -122, -125
    );

    constant SUN_Y_LUT : coord_array := (
        100,  99,  99,  98,  97,  96,  96,  95,
        94,  93,  93,  92,  91,  90,  90,  89,
        88,  87,  86,  85,  84,  83,  82,  81,
        80,  79,  78,  77,  76,  75,  74,  73,
        72,  71,  70,  69,  68,  67,  66,  65,
        64,  63,  62,  61,  60,  59,  58,  57,
        56,  55,  54,  53,  52,  51,  50,  49,
        48,  47,  46,  45,  44,  43,  42,  41,
        40,  39,  38,  37,  36,  35,  34,  33,
        32,  31,  30,  29,  28,  27,  26,  25,
        24,  23,  23,  22,  21,  20,  20,  19,
        18,  17,  17,  16,  15,  14,  14,  13,
        12,  12,  11,  11,  10,  10,   9,   9,
        8,   8,   8,   7,   7,   7,   7,   6,
        6,   6,   6,   6,   6,   6,   6,   6,
        6,   6,   6,   6,   6,   6,   6,   6,
        6,   6,   6,   6,   6,   6,   6,   6,
        6,   6,   7,   7,   7,   7,   8,   8,
        8,   9,   9,  10,  10,  11,  11,  12,
        12,  13,  14,  14,  15,  16,  17,  17,
        18,  19,  20,  20,  21,  22,  23,  23,
        24,  25,  26,  27,  28,  29,  30,  31,
        32,  33,  34,  35,  36,  37,  38,  39,
        40,  41,  42,  43,  44,  45,  46,  47,
        48,  49,  50,  51,  52,  53,  54,  55,
        56,  57,  58,  59,  60,  61,  62,  63,
        64,  65,  66,  67,  68,  69,  70,  71,
        72,  73,  74,  75,  76,  77,  78,  79,
        80,  81,  82,  83,  84,  85,  86,  87,
        88,  89,  90,  90,  91,  92,  93,  93,
        94,  95,  96,  96,  97,  98,  99,  99,
        100, 100, 100, 100, 100, 100, 100, 100
    );

    -- Bilddata (24x24 = 576 pixlar per bild)
    -- Total storlek: 576 * 2 = 1152 element
    type sprite_mem_t is array (0 to 1151) of std_logic_vector(11 downto 0); 
    
    constant CELESTIAL_MEM : sprite_mem_t := (

        -- =====================================================================
        -- Frame 0: SOLEN (Index 0 till 575)
        -- Baserad på din kod, men med Magenta (F0F) bakgrund.
        -- =====================================================================
        x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",
        x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",
        x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",
        x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",
        x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",
        x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",
        x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",
        x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",
        x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",
        x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",
        x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",
        x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",
        x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",
        x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",
        -- Frame 1: MÅNEN (Index 576 till 1151)
        -- Vit/Grå med kratrar och Magenta (F0F) bakgrund.
        -- Färgpalett: FFF (Vit), DDD (Ljusgrå), AAA (Mellan), 777 (Mörkgrå)
        x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"DDD",x"FFF",x"FFF",x"DDD",x"AAA",x"AAA",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"FFF",x"FFF",x"FFF",x"FFF",x"DDD",x"DDD",x"AAA",x"AAA",x"AAA",x"777",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"DDD",x"FFF",x"FFF",x"FFF",x"FFF",x"DDD",x"DDD",x"AAA",x"AAA",x"AAA",x"777",x"777",x"777",x"AAA",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"DDD",x"FFF",x"FFF",x"FFF",x"FFF",x"DDD",x"AAA",x"AAA",x"777",x"777",x"AAA",x"AAA",x"777",x"777",x"777",x"AAA",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"DDD",x"FFF",x"FFF",x"FFF",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"777",x"777",x"AAA",x"AAA",x"AAA",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"DDD",x"FFF",x"FFF",x"FFF",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"DDD",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"F0F",x"F0F",
        x"F0F",x"F0F",x"DDD",x"FFF",x"FFF",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"DDD",x"FFF",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"777",x"777",x"AAA",x"AAA",x"F0F",x"F0F",
        x"F0F",x"DDD",x"FFF",x"FFF",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"DDD",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"777",x"777",x"AAA",x"AAA",x"AAA",x"F0F",
        x"F0F",x"FFF",x"FFF",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"777",x"777",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"F0F",
        x"FFF",x"FFF",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"777",x"777",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"777",x"777",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",
        x"FFF",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"777",x"AAA",x"AAA",x"777",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",
        x"FFF",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"777",x"AAA",x"AAA",x"777",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",
        x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"DDD",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",
        x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"DDD",x"FFF",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",
        x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"DDD",x"DDD",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"777",x"777",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",
        x"F0F",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"777",x"777",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"F0F",
        x"F0F",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"F0F",
        x"F0F",x"F0F",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"777",x"777",x"AAA",x"AAA",x"AAA",x"AAA",x"F0F",x"F0F",
        x"F0F",x"F0F",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"777",x"777",x"AAA",x"AAA",x"AAA",x"AAA",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"777",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"777",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",
        x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"777",x"AAA",x"AAA",x"AAA",x"AAA",x"AAA",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F",x"F0F"

    );
end package;