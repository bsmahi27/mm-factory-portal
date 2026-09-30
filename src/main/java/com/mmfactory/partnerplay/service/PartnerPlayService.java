package com.mmfactory.partnerplay.service;

import com.mmfactory.partnerplay.dto.CreatePartnerPlayRequest;
import com.mmfactory.partnerplay.dto.PartnerPlayResponse;
import com.mmfactory.partnerplay.dto.UpdatePartnerPlayRequest;
import com.mmfactory.partnerplay.dto.PatchPartnerPlayRequest;
import com.mmfactory.partnerplay.dto.ChangePartnerPlayStatusRequest;
import java.util.List;

public interface PartnerPlayService {

    public List<PartnerPlayResponse> getAll();

    public PartnerPlayResponse getById(Long id);

    public PartnerPlayResponse create(CreatePartnerPlayRequest request);

    public PartnerPlayResponse update(Long id, UpdatePartnerPlayRequest request);

    public PartnerPlayResponse patchPartnerPlay(Long id, PatchPartnerPlayRequest request);

    public PartnerPlayResponse changeStatus(Long id, ChangePartnerPlayStatusRequest request);

    public void delete(Long id);
}