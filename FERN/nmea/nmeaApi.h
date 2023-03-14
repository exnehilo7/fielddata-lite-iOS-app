//
//  nmeaApi.h
//  FERN
//
//  Added by Hopp, Dan on 3/9/23.
//  From EosEADataEnt development kit.

//#ifndef nmeaApi_h // added from file creation
//#define nmeaApi_h // added from file creation

#ifndef nmea_nmeaApi_h
#define nmea_nmeaApi_h

#define NMEA_SATINPACK      (4)
#define NMEA_MAXSATPACKS    (9)
#define NMEA_MAXSAT         (NMEA_SATINPACK * NMEA_MAXSATPACKS)
#define NMEA_MAXSATINUSE    (12)

/**
 * NMEA packets type which parsed and generated by library
 */
typedef enum _nmeaPACKTYPE
{
    GPNON   = 0x0000,   /**< Unknown packet type. */
    GPGGA   = 0x0001,   /**< GGA - Essential fix data which provide 3D location and accuracy data. */
    GPGSA   = 0x0002,   /**< GSA - GPS receiver operating mode, SVs used for navigation, and DOP values. */
    GPGSV   = 0x0004,   /**< GSV - Number of SVs in view, PRN numbers, elevation, azimuth & SNR values. */
    GPRMC   = 0x0008,   /**< RMC - Recommended Minimum Specific GPS/TRANSIT Data. */
    GPVTG   = 0x0010,   /**< VTG - Actual track made good and speed over ground. */
    GPGST   = 0x0020,   /**< GST - GNSS pseudo range error statistics. */
    GNGST   = 0x0040,   /**< GST - GNSS pseudo range error statistics. */
    GLGSV   = 0x0100,   /**< GSV - Number of SVs in view, PRN numbers, elevation, azimuth & SNR values. GLONASS */
    GAGSV   = 0x0200,   /**< GSV - Number of SVs in view, PRN numbers, elevation, azimuth & SNR values. GALILEO */
    GBGSV   = 0x0400,   /**< GSV - Number of SVs in view, PRN numbers, elevation, azimuth & SNR values. BEIDOU */
    BDGSV   = 0x0800,   /**< GSV - Number of SVs in view, PRN numbers, elevation, azimuth & SNR values. BEIDOU */
    GQGSV   = 0x1000,   /**< GSV - Number of SVs in view, PRN numbers, elevation, azimuth & SNR values. QZSS */
    GNGSA   = 0x2000,  /**< GSA - GPS receiver operating mode, SVs used for navigation, and DOP values. All sources */
    
    
    PLTITHV = 0x2200,
    PLTITHT = 0x2400,
    PLTITML = 0x2600,
    
    
} nmeaPACKTYPE;

/**
 * Date and time data
 */
typedef struct _nmeaTIME
{
    int     year;       /**< Years since 1900 */
    int     mon;        /**< Months since January - [0,11] */
    int     day;        /**< Day of the month - [1,31] */
    int     hour;       /**< Hours since midnight - [0,23] */
    int     min;        /**< Minutes after the hour - [0,59] */
    int     sec;        /**< Seconds after the minute - [0,59] */
    int     hsec;       /**< Hundredth part of second - [0,99] */
    
} nmeaTIME;

/**
 * Position data in fractional degrees or radians
 */
typedef struct _nmeaPOS
{
    double lat;         /**< Latitude */
    double lon;         /**< Longitude */
    
} nmeaPOS;

/**
 * Information about satellite
 * @see nmeaSATINFO
 */
typedef struct _nmeaSATELLITE
{
    int     id;         /**< Satellite PRN number */
    int     in_use;     /**< Used in position fix */
    int     elv;        /**< Elevation in degrees, 90 maximum */
    int     azimuth;    /**< Azimuth, degrees from true north, 000 to 359 */
    int     sig;        /**< Signal, 00-99 dB */
    
} nmeaSATELLITE;

/**
 * Information about all satellites in view
 * @see nmeaINFO
 */
typedef struct _nmeaSATINFO
{
    int     inuse;      /**< Number of satellites in use (not those in view) */
    int     inview;     /**< Total number of satellites in view */
    nmeaSATELLITE sat[NMEA_MAXSAT]; /**< Satellites information */
    
} nmeaSATINFO;



/**
 * Summary GPS information from all parsed packets,
 * used also for generating NMEA stream
 * @see nmea_parse
 */
typedef struct _nmeaINFO
{
    int     smask;      /**< Mask specifying types of packages from which data have been obtained */
    
    nmeaTIME utc;       /**< UTC of position */
    
    int     sig;        /**< GPS quality indicator (0 = Invalid; 1 = Fix; 2 = Differential, 3 = SPS, 4 = RTK Fixed, 5 = RTK Float) */
    int     fix;        /**< Operating mode, used for navigation (1 = Fix not available; 2 = 2D; 3 = 3D) */
    double  dgps_age;   /**< Time in seconds since last DGPS update */
    int     dgps_sid;   /**< DGPS station ID number */
    double  geoidal_sep;/**< Geoidal separation (meters) */
    int     num_all_sats_used; /**< Total number of satellites in use */
    
    double  PDOP;       /**< Position Dilution Of Precision */
    double  HDOP;       /**< Horizontal Dilution Of Precision */
    double  VDOP;       /**< Vertical Dilution Of Precision */
    
    double  lat;        /**< Latitude in NDEG - +/-[degree][min].[sec/60] */
    double  lon;        /**< Longitude in NDEG - +/-[degree][min].[sec/60] */
    double  elv;        /**< Antenna altitude above/below mean sea level (geoid) in meters */
    double  speed;      /**< Speed over the ground in kilometers/hour */
    double  direction;  /**< Track angle in degrees True */
    double  declination; /**< Magnetic variation degrees (Easterly var. subtracts from true course) */
    
    double RMS;         /**< RMS value of the standard deviation of the range inputs to the navigation process. */
    double dev_lat;     /**< Standard deviation of latitude error (meters) */
    double dev_lon;     /**< Standard deviation of longitude error (meters) */
    double dev_elv;     /**< Standard deviation of altitude error (meters) */
    double dev_xy;      /**< Deviation of horizontal postion (meters) */
    double dev_xyz;     /**< Deviation of 3D position (meters) */
    
    nmeaSATINFO GPSsatinfo;         /**< GPS satellites information */
    nmeaSATINFO GLONASSsatinfo;     /**< GLONASS satellites information */
    nmeaSATINFO GALILEOsatinfo;     /**< GALILEO satellites information */
    nmeaSATINFO BEIDOUsatinfo;      /**< BEIDOU satellites information */
    nmeaSATINFO QZSSsatinfo;        /**< QZSS satellites information */
    
    
    //PLTIT
    //Horizontal Vector (HV) Download Messages
    double  PLTIT_HV_HDvalue;
    char    PLTIT_HV_HDvalueUnits;
    double  PLTIT_HV_AZvalue;
    char    PLTIT_HV_AZvalueUnits;
    double  PLTIT_HV_INCvalue;
    char    PLTIT_HV_INCvalueUnits;
    double  PLTIT_HV_SDvalue;
    char    PLTIT_HV_SDvalueUnits;
    
    //Height (HT) Download Messages
    double  PLTIT_HT_HTvalue;
    char    PLTIT_HT_HTvalueUnits;
    
    //Missing Line (ML) Download Messages
    double  PLTIT_ML_HD;
    char    PLTIT_ML_HDunits;
    double  PLTIT_ML_AZ;
    char    PLTIT_ML_AZunits;
    double  PLTIT_ML_INC;
    char    PLTIT_ML_INCunits;
    double  PLTIT_ML_SD;
    char    PLTIT_ML_SDunits;
    
} nmeaINFO;

/**
 * Summary GPS data parser
 * used to create the nmeaINFO result
 * @see nmea_parse
 */
typedef struct _nmeaPARSER
{
    void *top_node;
    void *end_node;
    unsigned char *buffer;
    int buff_size;
    int buff_use;
    
} nmeaPARSER;

typedef enum _nmeaVersion
{
    nmeaVersion0,       // Supports GPS(1), Glonass(2), Beidou(3) -> Default
    nmeaVersion1        // Supports GPS(1), Glonass(2), Galineo(3), N/A(4), Beidou(5), QZSS(6)
} nmeaVersion;


/**
 * API
 */
int nmea_parser_init(nmeaPARSER *parser);
void nmea_parser_destroy(nmeaPARSER *parser);
int nmea_parse(nmeaPARSER *parser,
               const char *buff, int buff_sz,
               nmeaINFO *info
               );

void nmea_zero_INFO(nmeaINFO *info);
void nmea_setVersion(nmeaVersion version);

int nmea_GPGGA_from_INFO(char *buff, nmeaINFO *info);

double nmea_ndeg2degree(double val);
double nmea_degree2ndeg(double val);


#endif /* nmeaApi_h */ // added from file creation