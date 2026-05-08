package com.botai.domain.agenda.exception;

import java.util.UUID;

public class StaffMemberNotFoundException extends AgendaDomainException {
    public StaffMemberNotFoundException(UUID id) {
        super("Staff member not found: " + id);
    }
}
