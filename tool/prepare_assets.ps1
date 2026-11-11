$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$zip = Get-ChildItem (Join-Path $env:USERPROFILE 'Downloads') -Filter '*PawPick*Assets*.zip' | Select-Object -First 1 -ExpandProperty FullName
$extract = Join-Path $root '_source_assets'
$destination = Join-Path $root 'assets\images\products'

if (!(Test-Path $zip)) { throw "Asset zip not found at $zip" }
if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
Expand-Archive -LiteralPath $zip -DestinationPath $extract

$files = Get-ChildItem $extract -Recurse -File
$map = @(
  @('CHBORCHICEN Heart Pet Dog Sweater', 'garments/dog/dog_heart_sweater.jpg'),
  @('Khaki Sherpa Fleece Plaid Hoodie Dress for Small Dogs & Cats 950', 'garments/dog/dog_sherpa_hoodie.jpg'),
  @('Preppy Pink Cable Knit Sweater Dress', 'garments/dog/dog_preppy_cable_dress.jpg'),
  @('Khaki Sherpa Fleece Plaid Hoodie Dress for Small Dogs & Cats 900', 'garments/cat/cat_sherpa_hoodie.jpg'),
  @('Luxury Cream Faux Fur Pet Dress', 'garments/cat/cat_faux_fur_dress.jpg'),
  @('Mogoko Funny Dog Cat Shark Costume', 'garments/cat/cat_shark_costume.jpg'),
  @('Coach Pink & White Polka Dot Leather Pet Collar', 'collars/collar_coach_polka_leather.jpg'),
  @('Maca Bates Chocolate & Pink Polka Dot Dog Collar with Bow Charm 1000', 'collars/collar_maca_bates_chocolate.jpg'),
  @('Personalized Mint Blue Ladybug Pattern Fabric Collar', 'collars/collar_ladybug_mint.jpg'),
  @('Pastel Striped Round Donut Pet Bed', 'beds/bed_pastel_donut.jpg'),
  @('Pink & White Checkered Plush Bolster', 'beds/bed_checkered_bolster.jpg'),
  @('Pink Strawberry Shaped Plush Pet Bed', 'beds/bed_strawberry_plush.jpg'),
  @('Azwraith Double Dog Cat Bowls', 'feeding/bowl_azwraith_double.jpg'),
  @('Coco Bow Quilted Faux Leather', 'feeding/bowl_coco_bow_quilted.jpg'),
  @('MACKENZIE-CHILDS Enamel Pet Bowl', 'feeding/bowl_enamel_pink_white.jpg'),
  @('MacKenzie-Childs Rosy Check', 'feeding/bowl_rosy_check.jpg'),
  @('Pink Gingham Strawberry Print Breathable Mesh', 'harness/harness_strawberry_mesh.jpg'),
  @('Maca Bates Chocolate & Pink Polka Dot Dog Collar with Bow Charm 1700', 'harness/collar_maca_bates_bow_charm.jpg'),
  @('DedCool Pet Shampoo', 'grooming/shampoo_dedcool.jpg'),
  @('OUAI Fur Bébé Pet Shampoo', 'grooming/shampoo_ouai_fur_bebe.jpg'),
  @('AllyZen Small Cat Tree', 'toys/cat_tree_beige_sisal.jpg'),
  @('Garden Sanctuary Pets Pink Mood Lollipop', 'toys/scratch_post_pink_lollipop.jpg'),
  @('PetsHome Pink Glitter Waterproof', 'travel/carrier_pink_glitter_purse.jpg'),
  @('oft Quilted Puffer Pet Carrier', 'travel/carrier_quilted_puffer_tote.jpg')
)

foreach ($entry in $map) {
  $source = $files | Where-Object { $_.Name -like "*$($entry[0])*" } | Select-Object -First 1
  if (!$source) { Write-Warning "Missing source: $($entry[0])"; continue }
  $target = Join-Path $destination ($entry[1] -replace '/', '\')
  New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
  Copy-Item $source.FullName $target -Force
}
Write-Host "Prepared local PawPick product assets in $destination"
