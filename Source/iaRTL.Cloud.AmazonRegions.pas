unit iaRTL.Cloud.AmazonRegions;

interface

type

  TAmazonRegion = record
    Code:string;
    DisplayName:string;
  end;


const

  AMAZON_REGION_US_EAST1 = 'us-east-1';
  AMAZON_REGION_US_EAST2 = 'us-east-2';
  AMAZON_REGION_US_WEST1 = 'us-west-1';
  AMAZON_REGION_US_WEST2 = 'us-west-2';
  AMAZON_REGION_USGOV_EAST1 = 'us-gov-east-1'; // special application process (Gov)
  AMAZON_REGION_USGOV_WEST1 = 'us-gov-west-1'; // special application process (Gov)
  AMAZON_REGION_AF_SOUTH1 = 'af-south-1';
  AMAZON_REGION_AP_EAST1 = 'ap-east-1';
  AMAZON_REGION_AP_SOUTHEAST3 = 'ap-southeast-3';
  AMAZON_REGION_AP_SOUTH1 = 'ap-south-1';
  AMAZON_REGION_AP_NORTHEAST3 = 'ap-northeast-3'; // special application process (Osaka)
  AMAZON_REGION_AP_NORTHEAST2 = 'ap-northeast-2';
  AMAZON_REGION_AP_SOUTHEAST1 = 'ap-southeast-1';
  AMAZON_REGION_AP_SOUTHEAST2 = 'ap-southeast-2';
  AMAZON_REGION_AP_NORTHEAST1 = 'ap-northeast-1';
  AMAZON_REGION_CA_CENTRAL1 = 'ca-central-1';
  AMAZON_REGION_CN_NORTH1 = 'cn-north-1'; // special application process (China)
  AMAZON_REGION_CN_NORTHWEST1 = 'cn-northwest-1'; // special application process (China)
  AMAZON_REGION_EU_CENTRAL1 = 'eu-central-1';
  AMAZON_REGION_EU_WEST1 = 'eu-west-1';
  AMAZON_REGION_EU_WEST2 = 'eu-west-2';
  AMAZON_REGION_EU_SOUTH1 = 'eu-south-1';
  AMAZON_REGION_EU_WEST3 = 'eu-west-3';
  AMAZON_REGION_EU_NORTH1 = 'eu-north-1';
  AMAZON_REGION_ME_SOUTH1 = 'me-south-1';
  AMAZON_REGION_SA_EAST1 = 'sa-east-1';


  // add new regions to end of array
  AMAZON_REGIONS: array [0 .. 23] of TAmazonRegion = (
    (Code:AMAZON_REGION_US_EAST1; DisplayName:'US East (N. Virginia)'),
    (Code:AMAZON_REGION_US_EAST2; DisplayName:'US East (Ohio)'),
    (Code:AMAZON_REGION_US_WEST1; DisplayName:'US West (N. California)'),
    (Code:AMAZON_REGION_US_WEST2; DisplayName:'US West (Oregon)'),
    (Code:AMAZON_REGION_USGOV_EAST1; DisplayName:'AWS GovCloud (US-East)'),
    (Code:AMAZON_REGION_USGOV_WEST1; DisplayName:'AWS GovCloud (US-West)'),
    (Code:AMAZON_REGION_AF_SOUTH1; DisplayName:'Africa (Cape Town)'),
    (Code:AMAZON_REGION_AP_SOUTH1; DisplayName:'Asia Pacific (Mumbai)'),
    (Code:AMAZON_REGION_AP_EAST1; DisplayName:'Asia Pacific (Hong Kong)'),
    (Code:AMAZON_REGION_AP_NORTHEAST1; DisplayName:'Asia Pacific (Tokyo)'),
    (Code:AMAZON_REGION_AP_NORTHEAST2; DisplayName:'Asia Pacific (Seoul)'),
    (Code:AMAZON_REGION_AP_NORTHEAST3; DisplayName:'Asia Pacific (Osaka)'),
    (Code:AMAZON_REGION_AP_SOUTHEAST1; DisplayName:'Asia Pacific (Singapore)'),
    (Code:AMAZON_REGION_AP_SOUTHEAST2; DisplayName:'Asia Pacific (Sydney)'),
    (Code:AMAZON_REGION_AP_SOUTHEAST3; DisplayName:'Asia Pacific (Jakarta)'),
    (Code:AMAZON_REGION_CA_CENTRAL1; DisplayName:'Canada (Central)'),
    (Code:AMAZON_REGION_EU_NORTH1; DisplayName:'Europe (Stockholm)'),
    (Code:AMAZON_REGION_EU_SOUTH1; DisplayName:'Europe (Milan)'),
    (Code:AMAZON_REGION_EU_WEST1; DisplayName:'Europe (Ireland)'),
    (Code:AMAZON_REGION_EU_WEST2; DisplayName:'Europe (London)'),
    (Code:AMAZON_REGION_EU_WEST3; DisplayName:'Europe (Paris)'),
    (Code:AMAZON_REGION_EU_CENTRAL1; DisplayName:'Europe (Frankfurt)'),
    (Code:AMAZON_REGION_ME_SOUTH1; DisplayName:'Middle East (Bahrain)'),
    (Code:AMAZON_REGION_SA_EAST1; DisplayName:'South America (São Paulo')
  );


  DEFAULT_AMAZON_REGION = AMAZON_REGION_US_EAST1;
implementation

end.
