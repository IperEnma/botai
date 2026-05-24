package com.botai.application.agenda.dto;

import java.util.List;
import java.util.UUID;

public record UpdateStaffServicesRequest(List<UUID> serviceIds) {
}
