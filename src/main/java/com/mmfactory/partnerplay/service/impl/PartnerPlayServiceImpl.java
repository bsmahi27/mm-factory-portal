package com.mmfactory.partnerplay.service.impl;

import com.mmfactory.common.exception.NotFoundException;
import com.mmfactory.partnerplay.dto.ChangePartnerPlayStatusRequest;
import com.mmfactory.partnerplay.dto.CreatePartnerPlayRequest;
import com.mmfactory.partnerplay.dto.PartnerPlayResponse;
import com.mmfactory.partnerplay.dto.UpdatePartnerPlayRequest;
import com.mmfactory.partnerplay.dto.PatchPartnerPlayRequest;
import com.mmfactory.partnerplay.entity.PartnerPlay;
import com.mmfactory.partnerplay.mapper.PartnerPlayMapper;
import com.mmfactory.partnerplay.repository.PartnerPlayRepository;
import com.mmfactory.partnerplay.service.PartnerPlayService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.util.List;


@Service
@RequiredArgsConstructor
public class PartnerPlayServiceImpl implements PartnerPlayService {

    private final PartnerPlayRepository repository;

    public List<PartnerPlayResponse> getAll() {
        return repository.findAll().stream().map(PartnerPlayMapper::toResponse).toList();
    }

    public PartnerPlayResponse getById(Long id) {
        var entity = repository.findById(id).orElseThrow(() -> new NotFoundException("Partner Play not found"));
        return PartnerPlayMapper.toResponse(entity);
    }

    public PartnerPlayResponse create(CreatePartnerPlayRequest request) {

        var partnerPlay = PartnerPlay.builder()
                .name(request.name())
                .partnerName(request.partnerName())
                .partnerTier(request.partnerTier())
                .businessLine(request.businessLine())
                .theme(request.theme())
                .eligibleCountryCodes(request.eligibleCountryCodes().toArray(String[]::new))
                .valueProposition(request.valueProposition())
                .ownerName(request.ownerName())
                .status("Draft")
                .linkedCampaignCount(0)
                .influencedPipelineMillions(BigDecimal.ZERO)
                .build();

        partnerPlay = repository.save(partnerPlay);
        return PartnerPlayMapper.toResponse(partnerPlay);
    }

    public PartnerPlayResponse update(Long id, UpdatePartnerPlayRequest request) {

        var partnerPlay = repository.findById(id).orElseThrow();
        partnerPlay.setTheme(request.theme());
        partnerPlay.setValueProposition(request.valueProposition());
        partnerPlay.setOwnerName(request.ownerName());
        assert request.eligibleCountryCodes() != null;
        partnerPlay.setEligibleCountryCodes(request.eligibleCountryCodes().toArray(String[]::new));
        partnerPlay = repository.save(partnerPlay);

        return PartnerPlayMapper.toResponse(partnerPlay);
    }

    public PartnerPlayResponse patchPartnerPlay(Long id, PatchPartnerPlayRequest request) {

        var partnerPlay = repository.findById(id).orElseThrow();

        if (request.theme() != null) {
            partnerPlay.setTheme(request.theme());
        }

        if (request.valueProposition() != null) {
            partnerPlay.setValueProposition(request.valueProposition());
        }

        if (request.ownerName() != null) {
            partnerPlay.setOwnerName(request.ownerName());
        }

        if (request.eligibleCountryCodes() != null) {
            partnerPlay.setEligibleCountryCodes(request.eligibleCountryCodes().toArray(String[]::new));
        }
        partnerPlay = repository.save(partnerPlay);
        return PartnerPlayMapper.toResponse(partnerPlay);
    }

    public PartnerPlayResponse changeStatus(Long id, ChangePartnerPlayStatusRequest request) {

        var partnerPlay = repository.findById(id).orElseThrow();
        partnerPlay.setStatus(request.status());
        partnerPlay = repository.save(partnerPlay);
        return PartnerPlayMapper.toResponse(partnerPlay);
    }

    public void delete(Long id) {
        repository.deleteById(id);
    }
}