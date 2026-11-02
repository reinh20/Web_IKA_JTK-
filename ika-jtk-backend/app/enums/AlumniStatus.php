<?php

namespace App\Enums;

enum AlumniStatus: string {
    case UNVERIFIED = 'UNVERIFIED';
    case PENDING = 'PENDING';
    case APPROVED = 'APPROVED';
    case ACTIVE = 'ACTIVE';
    case INACTIVE = 'INACTIVE';
    case REJECTED = 'REJECTED';
}
