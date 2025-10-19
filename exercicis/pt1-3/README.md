Exercici 1
- Creem dues instàncies amb una sola ordre, definint paràmetres mínims com ara la AMI el tipus d'instància i poc més.

- A la topologia podem veure, de fora a dins, la regió de N.Virginia (us-east-1). A dins la default VPC de AWS. A dins la Availability Zone (AZ) 1. I a dins de la AZ 1 les 6 subnets que venen per defecte. A la 1a subnet tenim les dues instancies creades amb terraform, que apareixen a la mateixa subnet perque han estat creades des de la mateixa ordre. 

Exercici 2
- Creem primer la VPC, definint el seu CIDR com a 10.0.0.0/16.
- Creem després 3 subnets dintre de la VPC, i dintre de la AZ 1. Assignant-li a cadascuna el CIDR corresponent.
- I creem dues instàncies idèntiques dintre de cadascuna de les 3 subnets.