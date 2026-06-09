# Tencent Cloud has no Internet Gateway resource: instances reach the internet
# via a public IP / EIP (or a NAT gateway for private subnets). A "public subnet"
# therefore only requires the VPC + subnet; the default route table handles local
# routing and public-IP egress automatically.

# Available zones in the current region (CVM product, since subnets host compute),
# used to spread subnets across AZs.
data "tencentcloud_availability_zones_by_product" "available" {
  product = "cvm"
}

locals {
  # Map each requested CIDR to an availability zone (one subnet per AZ), capped at
  # the number of zones the region actually offers.
  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs :
    data.tencentcloud_availability_zones_by_product.available.zones[idx].name => cidr
    if idx < length(data.tencentcloud_availability_zones_by_product.available.zones)
  }
}

resource "tencentcloud_vpc" "main" {
  name         = var.name
  cidr_block   = var.vpc_cidr
  is_multicast = false
  tags         = var.tags
}

resource "tencentcloud_subnet" "public" {
  for_each = local.public_subnets

  vpc_id            = tencentcloud_vpc.main.id
  name              = "${var.name}-public-${each.key}"
  availability_zone = each.key
  cidr_block        = each.value
  is_multicast      = false
  tags              = var.tags
}
